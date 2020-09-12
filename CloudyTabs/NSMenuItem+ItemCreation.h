//
//  NSMenuItem+ItemCreation.h
//  CloudyTabs
//
//  Created by Josh Parnham on 6/9/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSMenuItem (ItemCreation)

+ (NSMenuItem *)menuItemWithTitle:(NSString *)tabTitle URLPath:(NSString *)URLPath action:(SEL)action;

@end
