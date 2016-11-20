//
//  TRCSource.m
//
//
//  Created by Brian Olencki on 7/25/16.
//
//

#import "APTOSource.h"
#import "APTOManager.h"
#import "APTOSourceManager.h"

#import <UIKit/UIImage.h>

@implementation APTOSource
- (instancetype)initWithReleaseFile:(NSString*)file atURL:(NSString*)url withManager:(APTOManager*)manager  {
    if (self == [super init]) {
        _srcUrl = url;
        _manager = manager;
        [self parseFile:file];
    }
    return self;
}

- (void)parseFile:(NSString*)file {
    NSArray *aryFile = [file componentsSeparatedByString:@"\n"];
    
    NSMutableDictionary *dictItems = [NSMutableDictionary new];
    for (NSString *line in aryFile) {
        if ([line containsString:@": "]) {
            NSArray *aryDictkey = [line componentsSeparatedByString:@": "];
            if ([[aryDictkey objectAtIndex:0] isEqualToString:@"MD5Sum"] || [[aryDictkey objectAtIndex:0] isEqualToString:@"SHA1"] || [[aryDictkey objectAtIndex:0] isEqualToString:@"SHA256"]) continue;
            [dictItems setObject:[aryDictkey objectAtIndex:1] forKey:[aryDictkey objectAtIndex:0]];
        }
    }
    
//    _srcIcon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/CydiaIcon.png",_srcUrl]]]];
    
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.png", [[APTOManager sharedManager].cacheFile stringByAppendingString:@"/icons"],[APTOSourceManager fileNameForURL:_srcUrl]]];
    if (data) _srcIcon = [UIImage imageWithData:data];
    
    _srcOrigin = [dictItems objectForKey:@"Origin"];
    _srcLabel = [dictItems objectForKey:@"Label"];
    _srcSuite = [dictItems objectForKey:@"Suite"];
    _srcVersion = [dictItems objectForKey:@"Version"];
    _srcCodename = [dictItems objectForKey:@"Codename"];
    _srcArchitectures = [dictItems objectForKey:@"Architectures"];
    _srcComponents = [dictItems objectForKey:@"Components"];
    _srcDescription = [dictItems objectForKey:@"Description"];
    
    NSRange range = [file rangeOfString:@"MD5Sum:\n"];
    if (range.location != NSNotFound) {
        NSArray *aryMD5SUM = [[file substringFromIndex:range.location] componentsSeparatedByString:@"\n"];
        
        for (NSString *line in aryMD5SUM) {
            if ([line length] < 8) continue;
            if ([[line substringFromIndex:[line length]-8] isEqualToString:@"Packages"]) {
                _packageURL = [NSString stringWithFormat:@"%@/%@",_srcUrl,[[line componentsSeparatedByString:@" "] lastObject]];
                break;
            }
        }
    }
    
    if (!_packageURL) {
        _packageURL = [NSString stringWithFormat:@"%@/Packages",_srcUrl];
        if (![NSData dataWithContentsOfURL:[NSURL URLWithString:_packageURL]]) {
            _packageURL = [NSString stringWithFormat:@"%@/Packages.bz2",_srcUrl];
        }
    }
}
@end
