//
//  AppDelegate.m
//  CloudyTabsHelper
//
//  Created by Josh Parnham on 30/8/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import "AppDelegate.h"
#import "NSBundle+ApplicationPath.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *mainApplicationPath = [[NSBundle mainBundle] mainApplicationPath];
    [[NSWorkspace sharedWorkspace] launchApplication:mainApplicationPath];
    [NSApp terminate:nil];
}

@end
