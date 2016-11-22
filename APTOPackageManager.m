//
//  APTOPackageManager.m
//  
//
//  Created by Brian Olencki on 8/15/16.
//
//

#import "APTOPackageManager.h"
#import "APTOPackage.h"
#import "APTOSourceManager.h"
#import "APTOSource.h"
#import "APTOManager.h"

#import "APTOFileParser.h"

#import "BZipCompression/BZipCompression.h"

static NSString *APTOPackageManagerErrorDomain = @"com.aptobjc.error";

@implementation APTOPackageManager
+ (NSString*)fileNameForURL:(NSString*)url {
    NSString *output = url;
    
    NSRange range = [output rangeOfString:@"://"];
    if (range.location != NSNotFound) {
        output = [output substringFromIndex:range.location+3];
        output = [output stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    return output;
}
- (instancetype)initWithManager:(APTOManager*)manager withSourceManager:(APTOSourceManager*)sourceManager {
    if (self == [super init]) {
        _manager = manager;
        _sourceManager = sourceManager;
    }
    return self;
}
- (BOOL)updatePackages {
    __block BOOL output = YES;
    
    /*
     * outputs installed packages to text file named 'installed' this will be stored at the cacheFile directory
     */
#if !(TARGET_OS_SIMULATOR)
    system([[NSString stringWithFormat:@"dpkg-query --show > %@/installed",_manager.cacheFile] UTF8String]);
#endif
    /* -------------------- */
    
    __block NSInteger processes = [_sourceManager.sources count]-1;
    for (APTOSource *source in _sourceManager.sources) {
        dispatch_queue_t backgroundQueue1 = dispatch_queue_create([source.srcUrl UTF8String], 0);
        dispatch_async(backgroundQueue1, ^{
            BOOL success;
            
            NSRange range = NSMakeRange([source.packageURL length]-3, 3);
            if ([[source.packageURL substringWithRange:range] isEqualToString:@"bz2"]) {
                success = [self downloadSpecialPackage:source.packageURL];
            } else {
                success = [self downloadPackageList:source.packageURL];
            }
            if (output == YES) output = success;
            processes--;
        });
    }
    
    while (processes > 0) {
        [NSThread sleepForTimeInterval:0];
    }
    
    return output;
}
- (NSSet*)packages {
    
    NSMutableSet *packages = [NSMutableSet new];
    
    @autoreleasepool {
        [_sourceManager iterateThroughSources:^(APTOSource *source) {
            [packages addObjectsFromArray:[[self packagesForSource:source] allObjects]];
        }];
    }

    return packages;
}
- (NSSet*)packagesForSource:(APTOSource*)source {
    NSMutableSet *packages = [NSMutableSet new];
    
    NSString *filePath = [_manager.cacheFile stringByAppendingFormat:@"/lists/%@",[APTOPackageManager fileNameForURL:source.packageURL]];
    
    APTOFileParser *reader = [[APTOFileParser alloc] initWithFilePath:filePath];
    [reader enumeratePackageContentsUsingBlock:^(NSString *packageContents) {
        [self parseListWithPackageInfo:packageContents callBack:^(NSDictionary *dict) {
            APTOPackage *package = [[APTOPackage alloc] initWithControlFile:dict];
            package.installed = [self isInstalled:package.pkgPackage];
            package.pkgSource = source;
            [packages addObject:package];
        }];
    }];
    reader = nil;
    
    return packages;
}
- (NSArray*)installedPackages {
    NSString *contents = [self contentsOfFile:[NSString stringWithFormat:@"%@/installed",_manager.cacheFile]];
    
    NSArray *lines = [contents componentsSeparatedByString:@"\n"];
    
    NSMutableArray *installed = [NSMutableArray new];
    for (NSString *line in lines) {
        if ([line length] <= 1) continue;
        NSArray *info = [line componentsSeparatedByString:@"\t"];
        [installed addObject:@{
                               @"Package" : [info objectAtIndex:0],
                               @"Version" : [info objectAtIndex:1],
                               }];
        
        info = nil;
    }
    lines = nil;
    contents = nil;
    
    return installed;
}
- (BOOL)isInstalled:(NSString*)bundleIdentifier {
    BOOL output = NO;
    NSArray *installed = [self installedPackages];
    
    for (NSDictionary *info in installed) {
        if ([[info objectForKey:@"Package"] isEqualToString:bundleIdentifier]) {
            output = YES;
            break;
        }
    }
    installed = nil;
    
    return output;
}

#pragma mark - Gathering Packages
- (void)parseListWithPackageInfo:(NSString*)fileContents callBack:(void(^)(NSDictionary *dict))packageIterator {
    if (!packageIterator) return;
    
    NSArray *aryPackages = [fileContents componentsSeparatedByString:@"\n\n"];
    
    for (NSString *package in aryPackages) {
        NSArray *packageItems = [package componentsSeparatedByString:@"\n"];
        NSMutableDictionary *dictItems = [NSMutableDictionary new];
        for (NSString *item in packageItems) {
            if ([item containsString:@": "]) {
                NSArray *aryDictkey = [item componentsSeparatedByString:@": "];
                [dictItems setObject:[aryDictkey objectAtIndex:1] forKey:[aryDictkey objectAtIndex:0]];
                aryDictkey = nil;
            }
        }
        if ([dictItems objectForKey:@"Package"]) packageIterator(dictItems);
        dictItems = nil;
        packageItems = nil;
    }
}

#pragma mark - Managing Packages
- (APTOPackage*)packageWithBundleIdentifier:(NSString*)bundleIdentifer {
    __block APTOPackage *finalPackage = nil;
    
    @autoreleasepool {
        [_sourceManager iterateThroughSources:^(APTOSource *source) {
            if (finalPackage == nil) {
                @autoreleasepool {
                    for (APTOPackage *package in [[self packagesForSource:source] allObjects]) {
                        if ([package.pkgPackage isEqualToString:bundleIdentifer]) {
                            finalPackage = package;
                            break;
                        }
                    }
                }
            }
        }];
    }
    
    return finalPackage;
}
- (BOOL)install:(APTOPackage*)package callBack:(PackageManagerCallBack)callBack {
    BOOL output = NO;
    
    NSError *error = nil;
    NSArray *dependancies = [self dependanciesForPackage:package error:&error];
    if (error) {
        if (callBack) callBack(error.localizedDescription);
        return NO;
    }
    NSArray *conflicts = [self conflictsForPackage:package error:&error];
    if (error) {
        if (callBack) callBack(error.localizedDescription);
        return NO;
    }
    
    if (dependancies) {
        for (APTOPackage *_package in dependancies) {
            [self install:_package callBack:^(NSString *line) {
                if (callBack) callBack(line);
            }];
        }
    }
    
    if (conflicts) {
        for (APTOPackage *_package in conflicts) {
            [self remove:_package callBack:^(NSString *line) {
                if (callBack) callBack(line);
            }];
        }
    }
    
    
    
//    XXX: Actually install package
    
    return output;
}
- (BOOL)remove:(APTOPackage*)package callBack:(PackageManagerCallBack)callBack {
    BOOL output = NO;
    
//    XXX: Actually remove package
    
    return output;
}
- (NSArray*)conflictsForPackage:(APTOPackage*)package error:(NSError**)error {
    NSMutableArray *aryPackages = [NSMutableArray new];
    
    BOOL firmwareCheck = NO;
    
    for (NSString *item in package.pkgConflicts) {
        NSString *bundleIdentifier = item;
        NSString *version = nil;
        
        NSRange range = [item rangeOfString:@"("];
        if (range.location != NSNotFound) {
            if ([[bundleIdentifier substringToIndex:range.location] isEqualToString:@""]) {
                bundleIdentifier = [bundleIdentifier substringFromIndex:1];
                bundleIdentifier = [bundleIdentifier substringToIndex:[bundleIdentifier length]-1];
                range = [bundleIdentifier rangeOfString:@"("];
            }
            version = [bundleIdentifier substringFromIndex:range.location];
            version = [version stringByReplacingOccurrencesOfString:@"(" withString:@""];
            version = [version stringByReplacingOccurrencesOfString:@")" withString:@""];
            bundleIdentifier = [bundleIdentifier substringToIndex:range.location];
        }
        
        if ([bundleIdentifier isEqualToString:@"firmware"]) {
            NSString *currentVersion = [NSString stringWithFormat:@"%li.%li.%li",(long)[[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,(long)[[NSProcessInfo processInfo] operatingSystemVersion].minorVersion,(long)[[NSProcessInfo processInfo] operatingSystemVersion].patchVersion];
            
            if ([version containsString:@">>"]) { /* greater than */
                version = [version stringByReplacingOccurrencesOfString:@">>" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedAscending) break;
            } else if ([version containsString:@"<<"]) { /* less than */
                version = [version stringByReplacingOccurrencesOfString:@"<<" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedDescending) break;
            } else if ([version containsString:@"<="]) { /* less than or equal to */
                version = [version stringByReplacingOccurrencesOfString:@"<=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] == NSOrderedAscending) break;
            } else if ([version containsString:@">="]) { /* greater than or eaqual to */
                version = [version stringByReplacingOccurrencesOfString:@">=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] == NSOrderedDescending) break;
            } else if ([version containsString:@"="]) { /* equal to */
                version = [version stringByReplacingOccurrencesOfString:@"=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedSame) break;
            }
            firmwareCheck = YES;
        } else {
            APTOPackage *_package = [self packageWithBundleIdentifier:bundleIdentifier];
            
            if (_package) {
                if ([version containsString:@">>"]) { /* greater than */
                    version = [version stringByReplacingOccurrencesOfString:@">>" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedAscending) break;
                } else if ([version containsString:@"<<"]) { /* less than */
                    version = [version stringByReplacingOccurrencesOfString:@"<<" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedDescending) break;
                } else if ([version containsString:@"<="]) { /* less than or equal to */
                    version = [version stringByReplacingOccurrencesOfString:@"<=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] == NSOrderedAscending) break;
                } else if ([version containsString:@">="]) { /* greater than or eaqual to */
                    version = [version stringByReplacingOccurrencesOfString:@">=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] == NSOrderedDescending) break;
                } else if ([version containsString:@"="]) { /* equal to */
                    version = [version stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedSame) break;
                }
                [aryPackages addObject:_package];
            } else {
                break;
            }
        }
    }
    
    if ([aryPackages count] < [package.pkgConflicts count]-firmwareCheck) {
        if (error) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Package conflict (%@) was not found",[package.pkgConflicts objectAtIndex:[aryPackages count]+firmwareCheck]],
                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Conflict not found for package %@.",package.pkgPackage],
                                       NSLocalizedRecoverySuggestionErrorKey: @"Something seriously f*cked up",                                       };
            *error = [NSError errorWithDomain:APTOPackageManagerErrorDomain code:-13 userInfo:userInfo];
        }
        return nil;
    }
    return aryPackages;
}
- (NSArray*)dependanciesForPackage:(APTOPackage*)package error:(NSError**)error {
    NSMutableArray *aryPackages = [NSMutableArray new];
    
    BOOL firmwareCheck = NO;
    
    for (NSString *item in package.pkgDepends) {
        NSString *bundleIdentifier = item;
        NSString *version = nil;
        
        NSRange range = [item rangeOfString:@"("];
        if (range.location != NSNotFound) {
            if ([[bundleIdentifier substringToIndex:range.location] isEqualToString:@""]) {
                bundleIdentifier = [bundleIdentifier substringFromIndex:1];
                bundleIdentifier = [bundleIdentifier substringToIndex:[bundleIdentifier length]-1];
                range = [bundleIdentifier rangeOfString:@"("];
            }
            version = [bundleIdentifier substringFromIndex:range.location];
            version = [version stringByReplacingOccurrencesOfString:@"(" withString:@""];
            version = [version stringByReplacingOccurrencesOfString:@")" withString:@""];
            bundleIdentifier = [bundleIdentifier substringToIndex:range.location];
        }
        
        if ([bundleIdentifier isEqualToString:@"firmware"]) {
            NSString *currentVersion = [NSString stringWithFormat:@"%li.%li.%li",(long)[[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,(long)[[NSProcessInfo processInfo] operatingSystemVersion].minorVersion,(long)[[NSProcessInfo processInfo] operatingSystemVersion].patchVersion];
            
            if ([version containsString:@">>"]) { /* greater than */
                version = [version stringByReplacingOccurrencesOfString:@">>" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedAscending) break;
            } else if ([version containsString:@"<<"]) { /* less than */
                version = [version stringByReplacingOccurrencesOfString:@"<<" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedDescending) break;
            } else if ([version containsString:@"<="]) { /* less than or equal to */
                version = [version stringByReplacingOccurrencesOfString:@"<=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] == NSOrderedAscending) break;
            } else if ([version containsString:@">="]) { /* greater than or eaqual to */
                version = [version stringByReplacingOccurrencesOfString:@">=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] == NSOrderedDescending) break;
            } else if ([version containsString:@"="]) { /* equal to */
                version = [version stringByReplacingOccurrencesOfString:@"=" withString:@""];
                if ([self compareVersion:version toVersion:currentVersion] != NSOrderedSame) break;
            }
            firmwareCheck = YES;
        } else {
            APTOPackage *_package = [self packageWithBundleIdentifier:bundleIdentifier];
            
            if (_package) {
                if ([version containsString:@">>"]) { /* greater than */
                    version = [version stringByReplacingOccurrencesOfString:@">>" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedAscending) break;
                } else if ([version containsString:@"<<"]) { /* less than */
                    version = [version stringByReplacingOccurrencesOfString:@"<<" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedDescending) break;
                } else if ([version containsString:@"<="]) { /* less than or equal to */
                    version = [version stringByReplacingOccurrencesOfString:@"<=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] == NSOrderedAscending) break;
                } else if ([version containsString:@">="]) { /* greater than or eaqual to */
                    version = [version stringByReplacingOccurrencesOfString:@">=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] == NSOrderedDescending) break;
                } else if ([version containsString:@"="]) { /* equal to */
                    version = [version stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    if ([self compareVersion:version toVersion:_package.pkgVersion] != NSOrderedSame) break;
                }
                [aryPackages addObject:_package];
            } else {
                break;
            }
        }
    }
    
    if ([aryPackages count] < [package.pkgDepends count]-firmwareCheck) {
        if (error) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Package dependancy (%@) was not found",[package.pkgDepends objectAtIndex:[aryPackages count]+firmwareCheck]],
                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Dependancy not found for package %@.",package.pkgPackage],
                                       NSLocalizedRecoverySuggestionErrorKey: @"A different source may be needed.",                                       };
            *error = [NSError errorWithDomain:APTOPackageManagerErrorDomain code:-13 userInfo:userInfo];
        }
        return nil;
    }
    return aryPackages;
}

#pragma mark - Other
- (BOOL)downloadPackageList:(NSString*)url {
    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    
    if (urlData) {
        if ([[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] containsString:@"<!DOCTYPE html PUBLIC"]) return NO;
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", [_manager.cacheFile stringByAppendingString:@"/lists"],[APTOPackageManager fileNameForURL:url]];
        return [urlData writeToFile:filePath atomically:YES];
    }
    return NO;
}
- (BOOL)downloadSpecialPackage:(NSString*)url {
    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (urlData) {
        if ([[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] containsString:@"<!DOCTYPE html PUBLIC"]) return NO;
        
        NSData *decompressedData = [BZipCompression decompressedDataWithData:urlData error:nil];
        if (decompressedData) {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", [_manager.cacheFile stringByAppendingString:@"/lists"],[APTOPackageManager fileNameForURL:url]];
            return [decompressedData writeToFile:filePath atomically:YES];
        }
    }
    
    return NO;
}
- (NSString*)contentsOfFile:(NSString*)file {
    NSString *output = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    if (!output) output = [NSString stringWithContentsOfFile:file encoding:NSASCIIStringEncoding error:nil];
    
    return output;
}
- (NSComparisonResult)compareVersion:(NSString*)versionOne toVersion:(NSString*)versionTwo {
    NSArray* versionOneComp = [versionOne componentsSeparatedByString:@"."];
    NSArray* versionTwoComp = [versionTwo componentsSeparatedByString:@"."];
    
    NSInteger pos = 0;
    
    while ([versionOneComp count] > pos || [versionTwoComp count] > pos) {
        NSInteger v1 = [versionOneComp count] > pos ? [[versionOneComp objectAtIndex:pos] integerValue] : 0;
        NSInteger v2 = [versionTwoComp count] > pos ? [[versionTwoComp objectAtIndex:pos] integerValue] : 0;
        if (v1 < v2) {
            return NSOrderedAscending;
        }
        else if (v1 > v2) {
            return NSOrderedDescending;
        }
        pos++;
    }
    
    return NSOrderedSame;
}
@end
