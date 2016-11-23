//
//  APTOSourceManager.m
//  test
//
//  Created by Brian Olencki on 8/11/16.
//  Copyright © 2016 bolencki13. All rights reserved.
//

#import "APTOSourceManager.h"
#import "APTOManager.h"
#import "APTOSource.h"

@interface APTOManager (Internal)
- (BOOL)checkIfDirectoryExists:(NSString*)path createIfNecessary:(BOOL)create;
@end

@implementation APTOSourceManager
+ (NSString*)cleanURL:(NSString*)url {
    NSRange range = [url rangeOfString:@"dists"];
    if (range.location != NSNotFound) return [url substringToIndex:range.location];
    else return url;
}
+ (NSString*)fileNameForURL:(NSString*)url {
    NSString *output = url;
    
    NSRange range = [output rangeOfString:@"://"];
    if (range.location != NSNotFound) {
        output = [output substringFromIndex:range.location+3];
        output = [output stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    output = [output stringByAppendingString:@"_Release"];
    return output;
}
- (instancetype)initWithManager:(APTOManager *)manager {
    self = [super init];
    if (self) {
        _manager = manager;
    }
    return self;
}
- (void)iterateThroughSources:(SourceIterator)iterator {
    for (APTOSource *source in self.sources) iterator(source);
}
- (NSArray*)sources {
    NSMutableArray *arySources = [NSMutableArray new];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_manager.sourceFile error:nil];
    for (NSString *file in directory) {
        NSString *content = [self contentsOfFile:[_manager.sourceFile stringByAppendingFormat:@"/%@",file]];
        if (![content isEqualToString:@""] && content != nil) {
            NSArray *aryList = [content componentsSeparatedByString:@"\n"];

            for (NSString *item in aryList) {
                if ([item length] < 4 || ![[item substringWithRange:NSMakeRange(0,3)] isEqualToString:@"deb"]) continue;
                
                NSString *temp = [item substringWithRange:NSMakeRange(4, [item length]-4)];
                temp = [temp stringByReplacingOccurrencesOfString:@" ./" withString:@""];
                
                NSRange original = [temp rangeOfString:@" "];
                if (NSNotFound != original.location) {
                    temp = [temp stringByReplacingCharactersInRange:original withString:@"dists/"];
                }
                temp = [temp stringByReplacingOccurrencesOfString:@" main" withString:@""];
                
                APTOSource *source = [[APTOSource alloc] initWithReleaseFile:[self contentsOfFile:[NSString stringWithFormat:@"%@/lists/%@",_manager.cacheFile,[APTOSourceManager fileNameForURL:temp]]] atURL:temp withManager:_manager];
                if (source) {
                    [arySources addObject:source];
                }
            }
        }
    }
    return arySources;
}

#pragma mark - Source Handling
- (BOOL)addSource:(NSString *)url toListLocation:(NSString*)list {
    NSString *_url;
    if (![[url substringFromIndex:[url length] - 1] isEqualToString:@"/"]) {
        _url = [url stringByAppendingString:@"/"];
    } else {
        _url = url;
    }
    
    if ([self downloadRelease:url]) {
        NSString *file = [self contentsOfFile:list];
        file = [file stringByAppendingString:[NSString stringWithFormat:@"deb %@ ./\n",_url]];
        
        return [file writeToFile:list atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    return NO;
}
- (BOOL)removeSource:(NSString *)url {
    NSString *filePath = [self filePathForSource:url];
    if ([filePath isEqualToString:@""]) return NO;
    
    NSString *fileContents = [self contentsOfFile:filePath];
    
    NSMutableString *newFile = [[NSMutableString alloc] initWithString:@""];
    
    NSArray *aryList = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *item in aryList) {
        if (![item containsString:[APTOSourceManager cleanURL:url]]) {
            [newFile appendString:[NSString stringWithFormat:@"%@\n",item]];
        }
    }
    
    return [newFile writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
- (BOOL)updateSources {
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_manager.sourceFile error:nil];
    
    __block NSInteger processes = [directory count]-1;
    for (NSString *file in directory) {
        dispatch_queue_t backgroundQueue1 = dispatch_queue_create([file UTF8String], 0);
        dispatch_async(backgroundQueue1, ^{
            NSString *content = [self contentsOfFile:[NSString stringWithFormat:@"%@/%@",_manager.sourceFile,file]];
            if (![content isEqualToString:@""] && content != nil) {
                NSArray *aryList = [content componentsSeparatedByString:@"\n"];
                
                for (NSString *item in aryList) {
                    dispatch_queue_t backgroundQueue2 = dispatch_queue_create([item UTF8String], 0);
                    dispatch_async(backgroundQueue2, ^{
                        if ([item length] < 4 || ![[item substringWithRange:NSMakeRange(0,3)] isEqualToString:@"deb"]) return;
                        
                        NSString *url = [item substringWithRange:NSMakeRange(4, [item length]-4)];
                        url = [url stringByReplacingOccurrencesOfString:@" ./" withString:@""];
                        
                        NSRange original = [url rangeOfString:@" "];
                        if (NSNotFound != original.location) {
                            url = [url stringByReplacingCharactersInRange:original withString:@"dists/"];
                        }
                        url = [url stringByReplacingOccurrencesOfString:@" main" withString:@""];
                        
                        [self downloadRelease:url];
                        [self downloadIcon:url];
                    });
                }
            }
            processes--;
        });
    }
    
    while (processes > 0) {
        [NSThread sleepForTimeInterval:0];
    }
    
    return YES;
}
- (NSString*)filePathForSource:(NSString*)url {
    NSString *_url;
    if (![[url substringFromIndex:[url length] - 1] isEqualToString:@"/"]) {
        _url = [url stringByAppendingString:@"/"];
    } else {
        _url = url;
    }
    _url = [APTOSourceManager cleanURL:_url];

    NSString *output = @"";
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_manager.sourceFile error:nil];
    for (NSString *file in directory) {
        NSString *filePath = [_manager.sourceFile stringByAppendingFormat:@"/%@",file];
        NSString *fileContents = [self contentsOfFile:filePath];
        
        if ([fileContents containsString:_url]) {
            output = [_manager.sourceFile stringByAppendingFormat:@"/%@",file];
            break;
        }
    }
    
    return output;
}

#pragma mark - File Handling
- (BOOL)sourceFileExists:(NSString*)file {
    return [[NSFileManager defaultManager] fileExistsAtPath:file];
}
- (BOOL)createSourceFile:(NSString*)file {
    return [[NSFileManager defaultManager] createDirectoryAtPath:file withIntermediateDirectories:YES attributes:nil error:nil];
}
- (NSString*)contentsOfFile:(NSString*)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        NSString *contents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
        return (contents ? contents : @"");
    } else return @"";
}
- (BOOL)downloadRelease:(NSString*)url {
    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[url stringByAppendingString:@"/Release"]]];
    
    if (urlData) {
        if ([[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] containsString:@"<!DOCTYPE html PUBLIC"]) return NO;
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", [_manager.cacheFile stringByAppendingString:@"/lists"],[APTOSourceManager fileNameForURL:url]];
        [_manager checkIfDirectoryExists:[filePath stringByDeletingLastPathComponent] createIfNecessary:YES];
        
        return [urlData writeToFile:filePath options:0 error:nil];
    }
    return NO;
}
- (BOOL)downloadIcon:(NSString*)url {
    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[url stringByAppendingString:@"/CydiaIcon.png"]]];
    
    if (urlData) {
        if ([[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] containsString:@"<!DOCTYPE html PUBLIC"]) return NO;
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", [_manager.cacheFile stringByAppendingString:@"/icons"],[APTOSourceManager fileNameForURL:url]];
        return [urlData writeToFile:filePath atomically:YES];
    }
    return NO;

}
@end
