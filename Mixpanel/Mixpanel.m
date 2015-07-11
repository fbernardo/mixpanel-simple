//
//  Mixpanel.m
//  mixpanel-simple
//
//  Created by Conrad Kramer on 10/2/14.
//  Copyright (c) 2014 DeskConnect. All rights reserved.
//

#import "Mixpanel.h"
#import "MPTracker.h"
#import "MPFlusher.h"

@implementation Mixpanel

- (instancetype)init {
    return [self initWithToken:nil cacheDirectory:nil];
}

- (instancetype)initWithToken:(NSString *)token cacheDirectory:(NSURL *)cacheDirectory {
    self = [super init];
    if (self) {
        NSURL *cacheURL = [cacheDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"Mixpanel-%@.json", [token substringToIndex:6]]];
        _tracker = [[MPTracker alloc] initWithToken:token cacheURL:cacheURL];
        _flusher = [[MPFlusher alloc] initWithCacheDirectory:cacheDirectory];

        if (!_tracker || !_flusher)
            return nil;
    }
    return self;
}

@end
