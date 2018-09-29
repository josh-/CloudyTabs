//
//  JPSyncReader.h
//  CloudyTabs
//
//  Created by Josh Parnham on 28/09/18.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "JPTabsContainer.h"

@interface JPSyncReader: NSObject <JPTabsContainer>

+ (BOOL)canReadFile;
+ (NSString *)filePath;

- (NSArray *)deviceIDs;
- (NSString *)deviceNameForID:(NSString *)deviceID;
- (NSArray *)tabsForDeviceID:(NSString *)deviceID;
- (NSDate *)modificationDate;

@end
