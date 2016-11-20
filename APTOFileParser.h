//
//  APTOFileParser.h
//  
//
//  Created by Brian Olencki on 8/19/16.
//
//

#import <Foundation/Foundation.h>

@interface APTOFileParser : NSObject {
    NSString * filePath;
    
    NSFileHandle * fileHandle;
    unsigned long long currentOffset;
    unsigned long long totalFileLength;    
}
@property (nonatomic, copy) NSString *lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;
- (instancetype)initWithFilePath:(NSString *)aPath withBreak:(NSString*)aBreak;
- (NSString *)readLine;
- (NSString *)readTrimmedLine;
- (void)enumerateLinesUsingBlock:(void(^)(NSString*, BOOL *))block;
@end