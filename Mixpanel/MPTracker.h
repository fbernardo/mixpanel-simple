//
//  MPTracker.h
//  mixpanel-simple
//
//  Created by Conrad Kramer on 11/16/14.
//  Copyright (c) 2014 DeskConnect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPTracker : NSObject

@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, copy) NSString *distinctId;
@property (nonatomic, readonly, copy) NSURL *cacheURL;
@property (nonatomic, copy) NSDictionary *defaultProperties;

- (instancetype)initWithToken:(NSString *)token cacheURL:(NSURL *)cacheURL NS_DESIGNATED_INITIALIZER;

- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;

- (void)createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID;
- (void)identify:(NSString *)distinctId;

- (void)flush:(void(^)())completion;

@end
