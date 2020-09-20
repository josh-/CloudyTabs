//
//  JPTabCSVExporter.h
//  CloudyTabs
//
//  Created by Josh Parnham on 13/9/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JPTabCSVExporter : NSObject

+ (void)exportTabs:(NSArray<NSDictionary *> *)tabData deviceName:(NSString *)deviceName;

@end

NS_ASSUME_NONNULL_END
