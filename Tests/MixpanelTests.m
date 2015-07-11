//
//  MixpanelTests.m
//  mixpanel-simple
//
//  Created by Conrad Kramer on 11/20/14.
//  Copyright (c) 2014 DeskConnect. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Mixpanel.h"
#import "MPTracker.h"

@interface MixpanelTests : XCTestCase

@end

@implementation MixpanelTests

- (void)testInvalidInitialization {
    XCTAssertNil([[Mixpanel alloc] initWithToken:@"abc123" cacheDirectory:[NSURL fileURLWithPath:@"/mixpanel/somefile"]]);
    XCTAssertNil([[Mixpanel alloc] initWithToken:nil cacheDirectory:[NSURL fileURLWithPath:@"/mixpanel/somefile"]]);
    XCTAssertNil([[Mixpanel alloc] initWithToken:@"abc123" cacheDirectory:nil]);
}

- (void)testCacheURLWithNoBundleIdentifier {
    NSURL *cacheDirectory = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]];
    Mixpanel *mixpanel = [[Mixpanel alloc] initWithToken:@"abc123" cacheDirectory:cacheDirectory];
    XCTAssertTrue([mixpanel.tracker.cacheURL isEqual:[cacheDirectory URLByAppendingPathComponent:@"Mixpanel-abc123.json"]]);
}

@end
