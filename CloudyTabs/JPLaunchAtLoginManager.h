//
//  JPLaunchAtLoginManager.h
//  CloudyTabs
//
//  Created by Josh Parnham on 30/8/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

@interface JPLaunchAtLoginManager : NSObject

+ (BOOL)willStartAtLogin:(NSString *)helperBundleId;
+ (void)setStartAtLogin:(NSString *)helperBundleId enabled:(BOOL)enabled;

@end
