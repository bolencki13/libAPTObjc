//
//  APTOPackageManager.h
//  
//
//  Created by Brian Olencki on 8/15/16.
//
//

#import <Foundation/Foundation.h>

@class APTOManager, APTOSourceManager, APTOPackage, APTOSource;

typedef void (^PackageManagerCallBack)(NSString *line);

@interface APTOPackageManager : NSObject
@property (nonatomic, retain, readonly) NSSet <APTOPackage *> *packages;
+ (NSString*)fileNameForURL:(NSString*)url;
- (instancetype)initWithManager:(APTOManager*)manager withSourceManager:(APTOSourceManager*)sourceManager;
- (BOOL)updatePackages;
- (NSSet*)packagesForSource:(APTOSource*)source;
- (APTOPackage*)packageWithBundleIdentifier:(NSString*)bundleIdentifer;
- (NSArray*)installedPackages;
- (BOOL)install:(APTOPackage*)package callBack:(PackageManagerCallBack)callBack;
- (NSArray*)dependanciesForPackage:(APTOPackage*)package;

@property (nonatomic, retain, readonly) APTOManager *manager;
@property (nonatomic, retain, readonly) APTOSourceManager *sourceManager;
@end
