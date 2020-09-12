//
//  JPCloudTabsDBReader.h
//  CloudyTabs
//
//  Created by Josh Parnham on 9/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

@interface JPCloudTabsDBReader: NSObject

- (BOOL)permissionsToReadFile;
- (NSString *_Nonnull)cloudTabsDBFile;
- (void)fetchTabData:(void (^_Nonnull)(NSArray<NSDictionary *> *_Nullable))completionHandler;
- (void)fetchDatabaseModificationDate:(void (^_Nonnull)(NSDate *_Nullable))completionHandler;

@end
