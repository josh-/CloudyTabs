//
//  JPAppDelegate.h
//  CloudyTabs
//
//  Created by Josh Parnham on 3/03/2014.
//  Copyright (c) 2014 Josh Parnham. All rights reserved.
//

#import "VDKQueue.h"

@interface JPAppDelegate : NSObject <NSApplicationDelegate, VDKQueueDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenu *menu;

@end
