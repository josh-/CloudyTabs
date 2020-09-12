//
//  NSURL+Extensions.m
//  CloudyTabs
//
//  Created by Josh Parnham on 28/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "NSURL+Extensions.h"

@implementation NSURL (Extensions)

+ (NSURL *)decodeURL:(NSString *)urlString {
    // See dot point 4 under "NSURL Deprecations" in "Foundation Release Notes for OS X v10.11"
    if ([NSURL respondsToSelector:@selector(URLWithDataRepresentation:relativeToURL:)]) {
        // Modern NSURL API available
        return [NSURL URLWithDataRepresentation:[urlString dataUsingEncoding:NSUTF8StringEncoding] relativeToURL:nil];
    }
    else {
        return [self legacyDecodeURL:urlString];
    }
}

+ (NSURL *)legacyDecodeURL:(NSString *)urlString {
    // Modern NSURL API not available, fall back to CoreFoundation implementation
    NSData *urlData = [urlString dataUsingEncoding:NSUTF8StringEncoding];
    CFURLRef urlRef = CFURLCreateWithBytes(kCFAllocatorSystemDefault, (const UInt8 *)urlData.bytes, urlData.length, kCFStringEncodingUTF8, NULL);
    if (!urlRef) {
        // Fallback to using ISO Latin encoding
        urlRef = CFURLCreateWithBytes(kCFAllocatorSystemDefault, (const UInt8 *)urlData.bytes, urlData.length, kCFStringEncodingISOLatin1, NULL);
    }
    return (__bridge NSURL *)urlRef;
}

+ (NSURL *)privacyAllFilesSystemPreferencesURL {
    return [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"];
}

@end
