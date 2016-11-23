
//  APTOFileParser.m
//  
//
//  Created by Brian Olencki on 8/19/16.
//
//

#import "APTOFileParser.h"

@interface APTOFileParser () {
    
}
@end

@implementation APTOFileParser
- (instancetype)initWithFilePath:(NSString*)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    }
    return self;
}
- (void)enumeratePackageContentsUsingBlock:(void(^)(NSString *packageContents))block {
    @autoreleasepool {
        FILE *file = fopen([_filePath UTF8String], "r");

        if (!file) {
            /* XXX: File will ocasionally (9/10 times) be NULL causeing a bad access crash. Something to due with the dispatch_async() in APTOPackageManager - updatePackages */
            NSLog(@"[libAPTObjc]: fopen() failed errno = %d",errno); /* errno = 2 (file or directory does not exist?) */
            
            [NSThread sleepForTimeInterval:2];/* Sleep for a little to possibly still writing to disk */
            file = fopen([_filePath UTF8String], "r"); /* Attempt to open file again */
            if (!file) return;
        }
        
        int lineBuffer = 256;
        char buffer[lineBuffer];
        
        NSString *packageContents = @"";
        while (fgets(buffer, sizeof(char)*lineBuffer, file) != NULL){
            NSString *line = [NSString stringWithUTF8String:buffer];
            
            if ([line isEqualToString:@"\n"]) {
                block(packageContents);
                packageContents = @"";
            } else {
                packageContents = [packageContents stringByAppendingString:line];
            }
        }
        fclose(file);
    }
}
@end
