//
//  CloudyTabsTests.m
//  CloudyTabsTests
//
//  Created by Josh Parnham on 28/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSURL+DecodeURL.h"

@interface NSURL (DecodeTesting)

+ (NSURL *)legacyDecodeURL:(NSString *)urlString;

@end

@interface NSURLDecodeURLTests : XCTestCase

@end

@implementation NSURLDecodeURLTests

- (void)testMaintainsHashEncoding {
    NSURL *finalURL = [NSURL URLWithString:@"https://www.nodebeginner.org/index-zh-cn.html#javascript-and-nodejs"];
    
    XCTAssertEqualObjects(finalURL, [NSURL decodeURL:@"https://www.nodebeginner.org/index-zh-cn.html#javascript-and-nodejs"]);
}

- (void)testEncodedURL {
    NSURL *finalURL = [NSURL URLWithString:@"http://%E2%9E%A1.ws/%E4%A8%B9"];
    
    XCTAssertEqualObjects(finalURL, [NSURL decodeURL:@"http://➡.ws/䨹"]);
}

- (void)testEncodedPath {
    NSURL *finalURL = [NSURL URLWithString:@"https://www.101domain.com/%E4%B8%AD%E5%9B%BD.htm"];
    
    XCTAssertEqualObjects(finalURL, [NSURL decodeURL:@"https://www.101domain.com/中国.htm"]);
}

#pragma mark - Legacy implementation tests

- (void)testLegacyMaintainsHashEncoding {
    NSURL *finalURL = [NSURL URLWithString:@"https://www.nodebeginner.org/index-zh-cn.html#javascript-and-nodejs"];
    
    XCTAssertEqualObjects(finalURL, [NSURL legacyDecodeURL:@"https://www.nodebeginner.org/index-zh-cn.html#javascript-and-nodejs"]);
}

- (void)testLegacyEncodedURL {
    NSURL *finalURL = [NSURL URLWithString:@"http://%E2%9E%A1.ws/%E4%A8%B9"];
    
    XCTAssertEqualObjects(finalURL, [NSURL legacyDecodeURL:@"http://➡.ws/䨹"]);
}

- (void)testLegacyEncodedPath {
    NSURL *finalURL = [NSURL URLWithString:@"https://www.101domain.com/%E4%B8%AD%E5%9B%BD.htm"];
    
    XCTAssertEqualObjects(finalURL, [NSURL legacyDecodeURL:@"https://www.101domain.com/中国.htm"]);
}

@end
