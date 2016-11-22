//
//  APTOPackage.m
//  
//
//  Created by Brian Olencki on 8/17/16.
//
//

#import "APTOPackage.h"
#import "APTOSource.h"

@implementation APTOPackage
- (instancetype)initWithControlFile:(NSDictionary*)control {
    if (self == [super init]) {
        _pkgPackage = [control objectForKey:@"Package"];
        if (!_pkgPackage) _pkgPackage = [control objectForKey:@"package"];
        
        _pkgDescription = [control objectForKey:@"Description"];
        if (!_pkgDescription) _pkgDescription = [control objectForKey:@"description"];
        
        _pkgName = [control objectForKey:@"Name"];
        if (!_pkgName) _pkgName = [control objectForKey:@"name"];
        if (!_pkgName) _pkgName = _pkgPackage;
        
        _pkgDepiction = [control objectForKey:@"Depiction"];
        if (!_pkgDepiction) _pkgDepiction = [control objectForKey:@"depiction"];
        
        _pkgAuthor = [control objectForKey:@"Author"];
        if (!_pkgAuthor) _pkgAuthor = [control objectForKey:@"author"];
        
        _pkgVersion = [control objectForKey:@"Version"];
        if (!_pkgVersion) _pkgVersion = [control objectForKey:@"version"];
            
        _pkgFileName = [control objectForKey:@"FileName"];
        if (!_pkgFileName) _pkgFileName = [control objectForKey:@"fileName"];
        
        if ([[control objectForKey:@"Tag"] containsString:@"cydia::commercial"]) _paid = YES;
        
        if ([control objectForKey:@"Depends"]) {
            _pkgDepends = [[[control objectForKey:@"Depends"] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
        } else if ([control objectForKey:@"depends"]) {
            _pkgDepends = [[[control objectForKey:@"depends"] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
        } else {
            _pkgDepends = nil;
        }
        
        if ([control objectForKey:@"Conflicts"]) {
            _pkgConflicts = [[[control objectForKey:@"Conflicts"] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
        } else if ([control objectForKey:@"conflicts"]) {
            _pkgConflicts = [[[control objectForKey:@"conflicts"] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
        } else {
            _pkgConflicts = nil;
        }
    }
    return self;
}
@end
