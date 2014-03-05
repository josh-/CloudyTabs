//
//  main.m
//  CloudyTabs
//
//  Created by Josh Parnham on 3/03/2014.
//  Copyright (c) 2014 Josh Parnham. All rights reserved.
//

#import "JPAppDelegate.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSApplication * application = [NSApplication sharedApplication];
        
        JPAppDelegate * appDelegate = [[JPAppDelegate alloc] init];
        
        [application setDelegate:appDelegate];
        [application run];
    }
    
    return EXIT_SUCCESS;
}
