//
//  JPReadingListReader.h
//  CloudyTabs
//
//  Created by Josh Parnham on 29/9/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

@interface JPReadingListReader : NSObject

- (NSString *_Nonnull)syncedBookmarksFile;

- (void)fetchReadingListItems:(void (^_Nonnull)(NSArray *_Nullable))completionHandler;
- (void)fetchReadingListModificationDate:(void (^_Nonnull)(NSDate *_Nullable))completionHandler;

@end
