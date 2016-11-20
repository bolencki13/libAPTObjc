//
//  APTOSourceManager.h
//  test
//
//  Created by Brian Olencki on 8/11/16.
//  Copyright © 2016 bolencki13. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APTOManager, APTOSource;

typedef void (^SourceIterator)(APTOSource *source);

@interface APTOSourceManager : NSObject
@property (nonatomic, retain, readonly) NSArray <APTOSource *> *sources;
+ (NSString*)cleanURL:(NSString*)url;
+ (NSString*)fileNameForURL:(NSString*)url;
- (instancetype)initWithManager:(APTOManager*)manager;
- (void)iterateThroughSources:(SourceIterator)iterator;
- (BOOL)addSource:(NSString *)url toListLocation:(NSString*)list;
- (BOOL)removeSource:(NSString*)url;
- (BOOL)updateSources;
- (NSString*)filePathForSource:(NSString*)url;

@property (nonatomic, retain, readonly) APTOManager *manager;
@end
