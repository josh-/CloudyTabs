//
//  JPSyncedPreferencesReader.h
//  CloudyTabs
//
//  Created by Josh Parnham on 9/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "JPTabsContainer.h"

@interface JPSyncedPreferencesReader : NSObject <JPTabsContainer>

+ (BOOL)canReadFile;
+ (NSString *)filePath;

- (NSArray *)deviceIDs;
- (NSString *)deviceNameForID:(NSString *)deviceID;
- (NSArray *)tabsForDeviceID:(NSString *)deviceID;
- (NSDate *)modificationDate;

@end
