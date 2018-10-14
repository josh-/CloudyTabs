//
//  BookmarkSync.h
//  CloudyTabs
//
//  Created by Josh Parnham on 5/8/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#import "BookmarkSync.h"

@implementation WBSFetchedCloudTabDeviceOrCloseRequest

@synthesize deviceOrCloseRequestDictionary=_deviceOrCloseRequestDictionary;
@synthesize uuidString=_uuidString;

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:_uuidString forKey:@"uuidString"];
    [aCoder encodeObject:_deviceOrCloseRequestDictionary forKey:@"deviceOrCloseRequestDictionary"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _uuidString = [aDecoder decodeObjectForKey:@"uuidString"];
        _deviceOrCloseRequestDictionary = [aDecoder decodeObjectForKey:@"deviceOrCloseRequestDictionary"];
    }
    return self;
}

- (nullable instancetype)initWithUUIDString:(id)arg1 deviceOrCloseRequestDictionary:(id)arg2 {
    self = [super init];
    if (self) {
        _uuidString = arg1;
        _deviceOrCloseRequestDictionary = arg2;
    }
    return self;
}

@end
