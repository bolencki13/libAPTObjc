//
//  APTOPackage.h
//  
//
//  Created by Brian Olencki on 8/17/16.
//
//

#import <Foundation/Foundation.h>

@class APTOSource;
@interface APTOPackage : NSObject
@property (nonatomic, retain, readonly) NSString *pkgPackage;
@property (nonatomic, retain, readonly) NSString *pkgDescription;
@property (nonatomic, retain, readonly) NSString *pkgName;
@property (nonatomic, retain, readonly) NSString *pkgDepiction;
@property (nonatomic, retain, readonly) NSString *pkgAuthor;
@property (nonatomic, retain, readonly) NSString *pkgVersion;
@property (nonatomic, retain, readonly) NSString *pkgFileName;
@property (nonatomic, retain, readonly) NSArray *pkgDepends;
@property (nonatomic, retain, readonly) NSArray *pkgConflicts;
- (instancetype)initWithControlFile:(NSDictionary*)control;

@property (nonatomic) BOOL installed;
@property (nonatomic, readonly) BOOL paid;
@property (nonatomic, retain) NSString *price;
@property (nonatomic, retain) APTOSource *pkgSource;
@end
