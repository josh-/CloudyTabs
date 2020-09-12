//
//  NSMenuItem+ItemCreation.m
//  CloudyTabs
//
//  Created by Josh Parnham on 6/9/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import "NSMenuItem+ItemCreation.h"
#import "NSURL+Extensions.h"
#import "DSFavIconManager.h"

@implementation NSMenuItem (ItemCreation)

const NSSize ICON_SIZE = {19, 19};

+ (NSMenuItem *)menuItemWithTitle:(NSString *)tabTitle URLPath:(NSString *)URLPath action:(SEL)action {
    NSMenuItem *tabMenuItem = [[NSMenuItem alloc] initWithTitle:tabTitle action:action keyEquivalent:@""];
    
    NSURL *URL = [NSURL decodeURL:URLPath];
    tabMenuItem.representedObject = URL;
    tabMenuItem.toolTip = URL.relativeString;
    if (URL.host != nil) {
        tabMenuItem.image = [[DSFavIconManager sharedInstance] iconForURL:tabMenuItem.representedObject downloadHandler:^(NSImage *image) {
            image.size = ICON_SIZE;
            tabMenuItem.image = image;
        }];
    } else {
        tabMenuItem.image = [DSFavIconManager sharedInstance].placeholder;
    }
    tabMenuItem.image.size = ICON_SIZE;
    
    return tabMenuItem;
}

@end
