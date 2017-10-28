//
//  NSURL+DecodeURL.h
//  CloudyTabs
//
//  Created by Josh Parnham on 28/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Decode)

+ (NSURL *)decodeURL:(NSString *)urlString;

@end
