//
//  APTOManager.m
//  test
//
//  Created by Brian Olencki on 8/11/16.
//  Copyright © 2016 bolencki13. All rights reserved.
//

#import "APTOManager.h"

@implementation APTOManager
+ (APTOManager*)sharedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        /*
         *
         * OLD SOURCES.LIST FILE
         * ---------------------
         *
         * /var/mobile/Library/Caches/com.saurik.Cydia/sources.list
         *
         */
        _sharedObject = [[self alloc] initWithSourceFileLocation:@"/etc/apt/sources.list.d/" cacheLocation:@"/var/lib/AptObjc/"];
    });
    return _sharedObject;
}
- (instancetype)initWithSourceFileLocation:(NSString*)source cacheLocation:(NSString*)cache {
    if (self == [super init]) {
        _sourceFile = source;
        _cacheFile = cache;
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
@end