//
//  NSBundle+ApplicationPath.m
//  CloudyTabsHelper
//
//  Created by Josh Parnham on 30/8/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import "NSBundle+ApplicationPath.h"

@implementation NSBundle (ApplicationPath)

- (NSString *)mainApplicationPath {
    NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
    NSArray *applicationPathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
    NSString *path = [NSString pathWithComponents:applicationPathComponents];
    return path;
}

@end
