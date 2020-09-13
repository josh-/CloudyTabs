//
//  NSData+ZlibInflate.h
//  CloudyTabs
//
//  Based off NSData+Compression from CocoaGit
//  https://github.com/geoffgarside/cocoagit/blob/master/Source/Categories/NSData+Compression.h
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ZlibInflate)

- (NSData *)ZlibInflate;

@end
