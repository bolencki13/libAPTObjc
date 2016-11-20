//
//  APTOFileParser.h
//  
//
//  Created by Brian Olencki on 8/19/16.
//
//

#import <Foundation/Foundation.h>

@interface APTOFileParser : NSObject
@property (nonatomic, retain, readonly) NSString *filePath;
- (instancetype)initWithFilePath:(NSString*)filePath;
- (void)enumeratePackageContentsUsingBlock:(void(^)(NSString *packageContents))block;
@end
