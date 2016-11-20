//
//  APTOManager.h
//  test
//
//  Created by Brian Olencki on 8/11/16.
//  Copyright © 2016 bolencki13. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APTOManager : NSObject
@property (nonatomic, retain, readonly) NSString *sourceFile;
@property (nonatomic, retain, readonly) NSString *cacheFile;
+ (APTOManager*)sharedManager;
- (instancetype)initWithSourceFileLocation:(NSString*)source cacheLocation:(NSString*)cache;
- (void)cleanCaches;
@end
