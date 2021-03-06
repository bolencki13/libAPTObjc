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
+ (APTOManager*)optimizedManager; /* This will return the best fit manager. It will be one of the two bellow of a custom version */
+ (APTOManager*)sharedCydiaManager; /* Will work with a legacy (or currently released) version of Cydia */
+ (APTOManager*)sharedManager;
- (instancetype)initWithSourceFileLocation:(NSString*)source cacheLocation:(NSString*)cache;
- (void)cleanCaches;
@end
