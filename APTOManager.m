//
//  APTOManager.m
//  test
//
//  Created by Brian Olencki on 8/11/16.
//  Copyright © 2016 bolencki13. All rights reserved.
//

#import "APTOManager.h"

@implementation APTOManager
+ (APTOManager*)optimizedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedOptimizedObject = nil;
    dispatch_once(&p, ^{
        if (DEBUG) {
            NSString *path = [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            _sharedOptimizedObject = [[self alloc] initWithSourceFileLocation:[NSString stringWithFormat:@"%@/etc/apt/sources.list.d/",path] cacheLocation:[NSString stringWithFormat:@"%@/var/lib/AptObjc/",path]];
        } else {
            if (TARGET_OS_SIMULATOR) {
                _sharedOptimizedObject = [APTOManager sharedManager];
            } else {
                _sharedOptimizedObject = [APTOManager sharedCydiaManager];
            }
        }
    });
    return _sharedOptimizedObject;
}
+ (APTOManager*)sharedCydiaManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedLegacyObject = nil;
    dispatch_once(&p, ^{
        /*
         *
         * OLD SOURCES.LIST FILE
         * ---------------------
         *
         * /var/mobile/Library/Caches/com.saurik.Cydia/sources.list
         *
         */
        _sharedLegacyObject = [[self alloc] initWithSourceFileLocation:@"/etc/apt/sources.list.d/" cacheLocation:@"/var/lib/AptObjc/"];
    });
    return _sharedLegacyObject;
}
+ (APTOManager *)sharedManager {
    static dispatch_once_t q = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&q, ^{
        _sharedObject = [[self alloc] initWithSourceFileLocation:[NSString stringWithFormat:@"%@/sources.list.d/",[[NSBundle mainBundle] bundlePath]] cacheLocation:[NSString stringWithFormat:@"%@/AptObjc/",[[NSBundle mainBundle] bundlePath]]];
    });
    return _sharedObject;
}
- (instancetype)initWithSourceFileLocation:(NSString*)source cacheLocation:(NSString*)cache {
    self = [super init];
    if (self == [super init]) {
        _sourceFile = source;
        _cacheFile = cache;
        
        [self checkIfDirectoryExists:_sourceFile createIfNecessary:YES];
        [self checkIfDirectoryExists:_cacheFile createIfNecessary:YES];
    }
    return self;
}
- (void)cleanCaches {
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.cacheFile stringByAppendingString:@"/lists/"] error:nil];
    for (NSString *file in directory) {
        NSString *path = [NSString stringWithFormat:@"%@/lists/%@",self.cacheFile,file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }

    directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.cacheFile stringByAppendingString:@"/icons/"] error:nil];
    for (NSString *file in directory) {
        NSString *path = [NSString stringWithFormat:@"%@/icons/%@",self.cacheFile,file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}
- (BOOL)checkIfDirectoryExists:(NSString*)path createIfNecessary:(BOOL)create {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        if (create) {
            return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}
@end
