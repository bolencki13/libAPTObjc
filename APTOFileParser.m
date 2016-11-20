//
//  APTOFileParser.m
//  
//
//  Created by Brian Olencki on 8/19/16.
//
//

#import "APTOFileParser.h"

@interface NSData (DDAdditions)
- (NSRange)rangeOfData_dd:(NSData *)dataToFind;
@end

@implementation NSData (DDAdditions)
- (NSRange)rangeOfData_dd:(NSData *)dataToFind {
    
    const void * bytes = [self bytes];
    NSUInteger length = [self length];
    
    const void * searchBytes = [dataToFind bytes];
    NSUInteger searchLength = [dataToFind length];
    NSUInteger searchIndex = 0;
    
    NSRange foundRange = {NSNotFound, searchLength};
    for (NSUInteger index = 0; index < length; index++) {
        if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex]) {
            if (foundRange.location == NSNotFound) {
                foundRange.location = index;
            }
            searchIndex++;
            if (searchIndex >= searchLength) { return foundRange; }
        } else {
            searchIndex = 0;
            foundRange.location = NSNotFound;
        }
    }
    return foundRange;
}
@end




@implementation APTOFileParser
- (instancetype)initWithFilePath:(NSString *)aPath withBreak:(NSString*)aBreak {
    if (self = [super init]) {
        fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
        if (fileHandle == nil) {
            self = nil;
            return nil;
        }
        
        _lineDelimiter = aBreak;
        filePath = aPath;
        currentOffset = 0ULL;
        _chunkSize = 10;
        [fileHandle seekToEndOfFile];
        totalFileLength = [fileHandle offsetInFile];
    }
    return self;
}
- (void)dealloc {
    [fileHandle closeFile];
    fileHandle = nil;
    filePath = nil;
    _lineDelimiter = nil;
    currentOffset = 0ULL;
}
- (NSString *)readLine {
    if (currentOffset >= totalFileLength) return nil;
    
    NSData * newLineData = [_lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle seekToFileOffset:currentOffset];
    NSMutableData * currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;
    
    @autoreleasepool {
        while (shouldReadMore) {
            if (currentOffset >= totalFileLength) { break; }
            NSData * chunk = [fileHandle readDataOfLength:_chunkSize];
            NSRange newLineRange = [chunk rangeOfData_dd:newLineData];
            if (newLineRange.location != NSNotFound) {
                NSRange finalRange = NSMakeRange(0, newLineRange.location+[newLineData length]);
                if (finalRange.location != NSNotFound && finalRange.location+finalRange.length <= chunk.length) {
                    chunk = [chunk subdataWithRange:finalRange];
                    shouldReadMore = NO;
                }
            }
            [currentData appendData:chunk];
            currentOffset += [chunk length];
        }
    }
    
    NSString *line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
    currentData = nil;
    return line;
}
- (NSString *)readTrimmedLine {
    return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block {
    NSString *line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine])) {
        block(line, &stop);
    }
}
@end