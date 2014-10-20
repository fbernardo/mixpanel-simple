//
//  Mixpanel.h
//
//  Created by Conrad Kramer on 10/2/14.
//  Copyright (c) 2014 DeskConnect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Mixpanel : NSObject {
    @private
    NSString *_token;
    NSString *_distinctId;
    NSDictionary *_defaultProperties;
    NSURL *_cacheURL;
    NSMutableArray *_eventQueue;
    NSMutableArray *_eventBuffer;
    NSArray *_batch;
    NSURLConnection *_connection;
    NSHTTPURLResponse *_response;
    NSError *_error;
    NSData *_data;
    NSTimer *_timer;
    BOOL _reading;
    BOOL _writing;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070)
    NSOperationQueue *_presentedItemOperationQueue;
    void (^_reader)(void (^reacquirer)(void));
    void (^_writer)(void (^reacquirer)(void));
#endif
}

@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, copy) NSString *distinctId;
@property (nonatomic, copy) NSDictionary *defaultProperties;

+ (instancetype)sharedInstanceWithToken:(NSString *)token cacheDirectory:(NSURL *)cacheDirectory;
+ (instancetype)sharedInstance;

- (instancetype)initWithToken:(NSString *)token cacheDirectory:(NSURL *)cacheDirectory;

- (void)identify:(NSString *)distinctId;

- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;

- (void)flush;

@end
