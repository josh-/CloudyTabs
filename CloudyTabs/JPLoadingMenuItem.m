//
//  JPLoadingMenuItem.m
//  CloudyTabs
//
//  Created by Josh Parnham on 1/10/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#import "JPLoadingMenuItem.h"

@implementation JPLoadingMenuItem

- (instancetype)initWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode {
    self = [super initWithTitle:string action:selector keyEquivalent:charCode];
    if (self) {
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
        progressIndicator.bezeled = NO;
        progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        progressIndicator.controlSize = NSSmallControlSize;
        progressIndicator.style = NSProgressIndicatorSpinningStyle;
        [progressIndicator sizeToFit];
        self.view = progressIndicator;
        
        [progressIndicator startAnimation:self];
    }
    return self;
}

@end
