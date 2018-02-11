//
//  JPUserDefaultsController.h
//  CloudyTabs
//
//  Created by Josh Parnham on 11/2/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPUserDefaultsController : NSObject

+ (void)registerUserDefaults;

+ (BOOL)shouldListAllDevices;

@end
