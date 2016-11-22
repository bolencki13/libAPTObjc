
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
        _filePath = filePath;
    }
    return self;
}
- (void)enumeratePackageContentsUsingBlock:(void(^)(NSString *packageContents))block {
    @autoreleasepool {
        FILE *file = fopen([_filePath UTF8String], "r");
        if (!file) return; /* XXX: File will ocasionally be NULL causeing a bad access crash. Something to due with the dispatch_async() in APTOPackageManager - updatePackages */
        
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
    }
}
@end
