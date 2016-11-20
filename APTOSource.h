//
//  TRCSource.h
//  
//
//  Created by Brian Olencki on 7/25/16.
//
//

#import <Foundation/Foundation.h>

@class UIImage, APTOManager;

@interface APTOSource : NSObject
@property (nonatomic, retain, readonly) NSString *srcUrl;
@property (nonatomic, retain, readonly) UIImage *srcIcon;
@property (nonatomic, retain, readonly) NSString *srcOrigin;
@property (nonatomic, retain, readonly) NSString *srcLabel;
@property (nonatomic, retain, readonly) NSString *srcSuite;
@property (nonatomic, retain, readonly) NSString *srcVersion;
@property (nonatomic, retain, readonly) NSString *srcCodename;
@property (nonatomic, retain, readonly) NSString *srcArchitectures;
@property (nonatomic, retain, readonly) NSString *srcComponents;
@property (nonatomic, retain, readonly) NSString *srcDescription;
- (instancetype)initWithReleaseFile:(NSString*)file atURL:(NSString*)url withManager:(APTOManager*)manager;
@property (nonatomic, retain, readonly) NSString *packageURL;
@property (nonatomic, retain, readonly) APTOManager *manager;
@end
