//
//  JPTabsContainer.h
//  CloudyTabs
//
//  Created by Josh Parnham on 10/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

@protocol JPTabsContainer <NSObject>

@required

+ (BOOL)canReadFile;
- (NSArray * _Nonnull)deviceIDs;
- (NSString * _Nonnull)deviceNameForID:(NSString * _Nonnull)deviceID;
- (NSArray * _Nonnull)tabsForDeviceID:(NSString * _Nonnull)deviceID;
- (NSDate * _Nullable)modificationDate;

@end
