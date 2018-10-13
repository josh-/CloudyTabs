//
//  JPSyncReader.h
//  CloudyTabs
//
//  Created by Josh Parnham on 28/09/18.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

@interface JPSyncReader: NSObject

- (void)fetchTabData:(void (^_Nonnull)(NSArray *_Nullable))completionHandler;

@end
