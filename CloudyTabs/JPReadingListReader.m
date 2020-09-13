//
//  JPReadingListReader.m
//  CloudyTabs
//
//  Created by Josh Parnham on 29/9/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#import "JPReadingListReader.h"

@implementation JPReadingListReader

- (void)fetchReadingListItems:(void (^_Nonnull)(NSArray<NSDictionary *> *_Nullable))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *readingListItems = [self readingListBookmarks];
        completionHandler(readingListItems);
    });
}

- (void)fetchReadingListModificationDate:(void (^_Nonnull)(NSDate *_Nullable))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *modificationDate = [self syncedBookmarksModificationDate];
        completionHandler(modificationDate);
    });
}

- (NSString *)syncedBookmarksFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *syncedPreferencesPath = [paths[0] stringByAppendingPathComponent:@"Safari"];
    return [syncedPreferencesPath stringByAppendingPathComponent:@"Bookmarks.plist"];
}


# pragma mark - Private

- (NSArray<NSDictionary *> *_Nullable)readingListBookmarks {
    NSDictionary *syncedBookmarksDictionary = [[NSDictionary alloc] initWithContentsOfFile:[self syncedBookmarksFile]];
    
    if (syncedBookmarksDictionary == nil) {
        return nil;
    }
    
    NSArray *bookmarks = syncedBookmarksDictionary[@"Children"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Title = 'com.apple.ReadingList'"];
    NSDictionary* readingList = [[bookmarks filteredArrayUsingPredicate:predicate] firstObject];
    
    if (readingList == nil) {
        return nil;
    }
    
    return readingList[@"Children"];
}

- (NSDate *)syncedBookmarksModificationDate {
    NSDate *modificationDate;
    [[NSURL fileURLWithPath:[self syncedBookmarksFile]] getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    return modificationDate;
}

@end
