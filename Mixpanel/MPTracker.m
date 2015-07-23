//
//  MPTracker.m
//  mixpanel-simple
//
//  Created by Conrad Kramer on 11/16/14.
//  Copyright (c) 2014 DeskConnect. All rights reserved.
//

#import "MPTracker.h"
#import "MPUtilities.h"
#import "MPFlushOperation.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

@implementation MPTracker {
    NSFileHandle *_handle;
    NSArray *_events;
    NSLock *_distinctLock;
    NSOperationQueue *_flushOperationQueue;
}

@synthesize distinctId = _distinctId;

+ (dispatch_queue_t)queue {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (dispatch_queue_attr_make_with_qos_class)
            attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, QOS_MIN_RELATIVE_PRIORITY + 5);
        queue = dispatch_queue_create("com.mixpanel.mixpanel.tracker", attr);
    });
    return queue;
}

- (instancetype)init {
    return [self initWithToken:nil cacheURL:nil];
}

- (instancetype)initWithToken:(NSString *)token cacheURL:(NSURL *)cacheURL {
    self = [super init];
    if (self) {
        if (!token.length) {
            NSLog(@"%@: Error: Invalid token provided: \"%@\"", self, token);
            return nil;
        }
        
        if (!cacheURL) {
            NSLog(@"%@: Error: Invalid cache URL provided: \"%@\"", self, cacheURL);
            return nil;
        }
        
        int fd;
        if ((fd = open(cacheURL.fileSystemRepresentation, O_WRONLY | O_APPEND | O_CREAT, 0644)) == -1) {
            NSLog(@"%@: Error: Cache URL is not writable: \"%@\"", self, cacheURL);
            return nil;
        }
        
        _token = token;
        _cacheURL = cacheURL;
        _events = [NSArray new];
        _distinctLock = [NSLock new];
        _handle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, token: %@>", NSStringFromClass([self class]), self, _token];
}

- (NSString *)distinctId {
    [_distinctLock lock];
    if (!_distinctId) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        UIDevice *device = [UIDevice currentDevice];
        _distinctId = ([device respondsToSelector:@selector(identifierForVendor)] ? [device.identifierForVendor UUIDString] : nil);
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
        _distinctId = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
        IOObjectRelease(ioRegistryRoot);
#endif
    }
    NSString *distinctId = _distinctId;
    [_distinctLock unlock];

    return distinctId;
}

- (void)track:(NSString *)event {
    [self track:event properties:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    NSParameterAssert(event);

    NSNumber *timestamp = [NSNumber numberWithInteger:(NSInteger)round([[NSDate date] timeIntervalSince1970])];

    NSMutableDictionary *mergedProperties = [NSMutableDictionary dictionaryWithDictionary:MPAutomaticProperties()];
    [mergedProperties addEntriesFromDictionary:properties];
    [mergedProperties setValue:timestamp forKey:@"time"];

    dispatch_async([[self class] queue], ^{
        [mergedProperties addEntriesFromDictionary:self.defaultProperties];
        [mergedProperties setValue:self.distinctId forKey:@"distinct_id"];
        [mergedProperties setValue:_token forKey:@"token"];
        
        NSDictionary *eventDictionary = MPJSONSerializableObject([NSDictionary dictionaryWithObjectsAndKeys:event, @"event", mergedProperties, @"properties", nil]);
        _events = [_events arrayByAddingObject:eventDictionary];
        
        if (flock(_handle.fileDescriptor, LOCK_EX) == -1) {
            NSLog(@"%@: Error: Could not lock file descriptor", self);
            return;
        }
                
        for (NSDictionary *event in _events) {
            NSError *error = nil;
            char endline = '\n';
            NSMutableData *data = [[NSJSONSerialization dataWithJSONObject:event options:0 error:&error] mutableCopy];
            [data appendBytes:&endline length:1];
            if (!data) {
                NSLog(@"%@: Error: Event \"%@\" could not be serialized", self, event);
                continue;
            }
            
            [_handle writeData:data];
            [_handle synchronizeFile];
        }
        
        _events = [NSArray new];
        
        if (flock(_handle.fileDescriptor, LOCK_UN) == -1)
            NSLog(@"%@: Error: Could not unlock file descriptor", self);
    });
}

- (void)createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID {
    if (!alias.length) {
        NSLog(@"%@: Error: Create alias called with invalid alias", self);
        return;
    }
    if (!distinctID.length) {
        NSLog(@"%@: Error: Create alias called with invalid distinct ID", self);
        return;
    }
    
    [self track:@"$create_alias" properties:@{@"distinct_id": distinctID, @"alias": alias}];
}

- (void)identify:(NSString *)distinctId {
    dispatch_async([[self class] queue], ^{
        [_distinctLock lock];
        _distinctId = distinctId;
        [_distinctLock unlock];
    });
}

#pragma mark - Flushing

- (void)flush:(void(^)())completion {
    if (!_flushOperationQueue)
        _flushOperationQueue = [NSOperationQueue new];
    
    MPFlushOperation *flushOperation = [[MPFlushOperation alloc] initWithCacheURL:_cacheURL];
    flushOperation.name = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [NSDate date]];
    flushOperation.completionBlock = completion;
    [_flushOperationQueue addOperation:flushOperation];
}

@end
