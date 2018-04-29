//
//  JPAppDelegate.m
//  CloudyTabs
//
//  Created by Josh Parnham on 3/03/2014.
//  Copyright (c) 2014 Josh Parnham. All rights reserved.
//

#import "JPAppDelegate.h"

#import <CoreFoundation/CoreFoundation.h>

#import <Sparkle/Sparkle.h>

#import "JPLaunchAtLoginManager.h"
#import "JPUserDefaultsController.h"
#import "DSFavIconManager.h"

#import "JPTabsContainer.h"
#import "JPSyncedPreferencesReader.h"
#import "JPCloudTabsDBReader.h"

#import "NSURL+DecodeURL.h"

@interface JPAppDelegate ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSDate *lastUpdateDate;

@property (strong, nonatomic) id<JPTabsContainer> tabContainer;

@end

@implementation JPAppDelegate

const NSSize ICON_SIZE = {19, 19};

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([JPCloudTabsDBReader canReadFile]) {
        self.tabContainer = [[JPCloudTabsDBReader alloc] init];
    } else if ([JPSyncedPreferencesReader canReadFile]) {
        self.tabContainer = [[JPSyncedPreferencesReader alloc] init];
    } else {
        NSLog(@"Unable to open CloudyTabs");
        NSLog(@"%@", [JPCloudTabsDBReader debugDescription]);
        NSLog(@"%@", [JPSyncedPreferencesReader debugDescription]);
        [NSApp terminate:self];
    }
    
    [DSFavIconManager sharedInstance].placeholder = [NSImage imageNamed:@"BookmarksDragImage"];
    [JPUserDefaultsController registerUserDefaults];
    
    [self createStatusItem];
    [self updateMenu];
    [self updateStatusItemToolTip];
    [self setupQueue];
    [self setupSparkle];
}

#pragma mark - Menu actions

- (void)tabMenuItemClicked:(id)sender
{
    NSURL *URL = [(NSMenuItem *)sender representedObject];
    
    if ([NSEvent modifierFlags] == NSCommandKeyMask) {
        [[NSWorkspace sharedWorkspace] openURLs:@[URL] withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
    else if ([NSEvent modifierFlags] == NSAlternateKeyMask) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        
        NSURL *URL = [[self.menu highlightedItem] representedObject];
        if (![pasteboard writeObjects:@[URL]]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to copy URL" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The URL was unable to be copied to the pasteboard."];
            [alert runModal];
        }
    }
    else {
        [[NSWorkspace sharedWorkspace] openURL:URL];
    }
}

- (void)deviceMenuItemClicked:(id)sender
{
    NSUInteger launch;
    if ([NSEvent modifierFlags] == NSCommandKeyMask) {
        launch = NSWorkspaceLaunchWithoutActivation;
    }
    else {
        launch = NSWorkspaceLaunchDefault;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSArray *tabs = [self.tabContainer tabsForDeviceID:[(NSMenuItem *)sender representedObject]];

        for (NSDictionary *tabDictionary in tabs) {
            NSURL *url = [NSURL decodeURL:tabDictionary[@"URL"]];

            [[NSWorkspace sharedWorkspace] openURLs:@[url] withAppBundleIdentifier:nil options:launch additionalEventParamDescriptor:nil launchIdentifiers:nil];
            usleep(500000);
        }
    });
}

- (void)openAtLoginToggled:(id)sender
{
    [self setStartAtLogin:(![self startAtLogin])];
}

#pragma mark - Menu validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(openAtLoginToggled:)) {
        if ([(NSMenuItem *)item respondsToSelector:@selector(setState:)]) {
            [(NSMenuItem *)item setState:[self startAtLogin]];
        }
    }
    return YES;
}

#pragma mark - Queue delegate

-(void)VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath;
{
    // Only update menu if the data has been updated since last refresh
    NSDate *fileModificationDate = [self.tabContainer modificationDate];
    BOOL newTabContainerData = [fileModificationDate laterDate:self.lastUpdateDate] == fileModificationDate;

    NSDate *readingListModificationDate = [self syncedBookmarksModificationDate];
    BOOL newReadingListData = [readingListModificationDate laterDate:self.lastUpdateDate] == readingListModificationDate;
    if (newTabContainerData || newReadingListData) {
        [self updateUserInterface];
    }
    return;
}

#pragma mark - Methods

- (NSString *)appBundleName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString *)appBundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (void)setupSparkle
{
    SUUpdater *updater = [[SUUpdater class] sharedUpdater];
    [updater checkForUpdatesInBackground];
}

- (void)setupQueue
{
    VDKQueue *queue = [[VDKQueue alloc] init];

    [queue addPath:[[self.tabContainer class] filePath] notifyingAbout:VDKQueueNotifyDefault];
    [queue addPath:[self syncedBookmarksFile] notifyingAbout:VDKQueueNotifyDefault];

    [queue setDelegate:self];
}

- (void)updateUserInterface
{
    [self updateMenu];
    [self updateStatusItemToolTip];
}

- (NSDictionary *)syncedBookmarksDictionary
{
    return [[NSDictionary alloc] initWithContentsOfFile:[self syncedBookmarksFile]];
}

- (NSString *)syncedBookmarksFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *syncedPreferencesPath = [paths[0] stringByAppendingPathComponent:@"Safari"];
    return [syncedPreferencesPath stringByAppendingPathComponent:@"Bookmarks.plist"];
}

- (NSDate *)syncedBookmarksModificationDate
{
    NSDate *modificationDate;
    [[NSURL fileURLWithPath:[self syncedBookmarksFile]] getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    return modificationDate;
}

- (NSArray *)readingListBookmarks
{
    NSArray *bookmarks = [self syncedBookmarksDictionary][@"Children"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Title = 'com.apple.ReadingList'"];
    NSDictionary* readingList = [[bookmarks filteredArrayUsingPredicate:predicate] firstObject];
    return readingList[@"Children"];
}

- (NSDate *)latestModificationDate
{
    NSDate *tabSyncModificationDate = [self.tabContainer modificationDate];
    NSDate *bookmarksSyncModificationDate = [self syncedBookmarksModificationDate];


    if (tabSyncModificationDate != nil && bookmarksSyncModificationDate != nil) {
        return [[@[tabSyncModificationDate, bookmarksSyncModificationDate] sortedArrayUsingSelector:@selector(compare:)] lastObject];
    } else if (tabSyncModificationDate != nil) {
        return tabSyncModificationDate;
    } else if (bookmarksSyncModificationDate != nil) {
        return bookmarksSyncModificationDate;
    } else {
        return nil;
    }
}

- (void)createStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setImage:[NSImage imageNamed:@"ToolbarCloudTabsTemplate"]];
    [self.statusItem setMenu:self.menu];
    [self.statusItem setEnabled:YES];
}

- (void)updateMenu
{
    [self.menu removeAllItems];
    
    NSMenu *devicesMenu = [[NSMenu alloc] initWithTitle:@"Devices"];
    [devicesMenu setAutoenablesItems:NO];
    
    for (NSString *deviceID in [self.tabContainer deviceIDs]) {
        NSArray *deviceTabs = [self.tabContainer tabsForDeviceID:deviceID];
        
        // Hide devices that don't have any tabs
        if (deviceTabs.count <= 0) {
            continue;
        }
        
        // Hide tabs from Mac where CloudyTabs is currently running on, unless the user has expliclty set the user default
        if ([JPUserDefaultsController shouldListAllDevices] == false && [[NSHost currentHost].localizedName isEqualToString:[self.tabContainer deviceNameForID:deviceID]]) {
            continue;
        }
        
        // Add a seperator if this device isn't the first in the list
        if (self.menu.itemArray.count > 0) {
            NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
            [self.menu addItem:seperatorItem];
        }
        
        // Add device to main list of tabs
        NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:[self.tabContainer deviceNameForID:deviceID] action:nil keyEquivalent:@""];
        [self.menu addItem:deviceMenuItem];
        
        // Add device to "Open All Tabs From" submenu
        NSString *localisedTabCount = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:deviceTabs.count] numberStyle:NSNumberFormatterNoStyle];
        NSString *openAllTabsFromDeviceMenuItemTitle = [NSString stringWithFormat:@"%@ (%@)", [self.tabContainer deviceNameForID:deviceID], localisedTabCount];
        NSMenuItem *openAllTabsFromDeviceMenuItem = [[NSMenuItem alloc] initWithTitle:openAllTabsFromDeviceMenuItemTitle action:@selector(deviceMenuItemClicked:) keyEquivalent:@""];
        openAllTabsFromDeviceMenuItem.representedObject = deviceID;
        if ([[self.tabContainer tabsForDeviceID:deviceID] count] < 1) {
            [openAllTabsFromDeviceMenuItem setEnabled:NO];
        }
        [devicesMenu addItem:openAllTabsFromDeviceMenuItem];

        for (NSDictionary *tabDictionary in [self.tabContainer tabsForDeviceID:deviceID]) {
            [self.menu addItem:[self makeMenuItemWithTitle:tabDictionary[@"Title"] URL:tabDictionary[@"URL"]]];
        }
    }

    if ([self readingListBookmarks].count > 0) {
        if (self.menu.itemArray.count > 0) {
            [self.menu addItem:[NSMenuItem separatorItem]];
        }

        NSMenuItem *readingListTitle = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reading List", @"") action:nil keyEquivalent:@""];
        [self.menu addItem:readingListTitle];

        for (NSDictionary *bookmarkDictionary in [self readingListBookmarks]) {
            [self.menu addItem:[self makeMenuItemWithTitle:bookmarkDictionary[@"URIDictionary"][@"title"] URL:bookmarkDictionary[@"URLString"]]];
        }
    }

    if (self.menu.itemArray.count > 0) {
        [self.menu addItem:[NSMenuItem separatorItem]];
    }

    if ([self.tabContainer deviceIDs].count > 1) {
        NSMenuItem *openAllTabsMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open All Tabs From", @"") action:nil keyEquivalent:@""];
        [self.menu addItem:openAllTabsMenu];
        [openAllTabsMenu setSubmenu:devicesMenu];
        [openAllTabsMenu setEnabled:([devicesMenu.itemArray count] > 1)];
    }
    
    NSMenuItem *openAtLoginItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Launch %@ At Login", @""), [self appBundleName]] action:@selector(openAtLoginToggled:) keyEquivalent:@""];
    [self.menu addItem:openAtLoginItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), [self appBundleName]] action:@selector(quit:) keyEquivalent:@"q"];
    [self.menu addItem:quitMenuItem];
    
    self.lastUpdateDate = [NSDate date];
}

- (NSMenuItem *)makeMenuItemWithTitle:(NSString *)tabTitle URL:(NSString *)tabURL {
    NSMenuItem *tabMenuItem = [[NSMenuItem alloc] initWithTitle:tabTitle action:@selector(tabMenuItemClicked:) keyEquivalent:@""];

    NSURL *URL = [NSURL decodeURL:tabURL];
    tabMenuItem.representedObject = URL;
    tabMenuItem.toolTip = URL.relativeString;
    if (URL.host != nil) {
        tabMenuItem.image = [[DSFavIconManager sharedInstance] iconForURL:tabMenuItem.representedObject downloadHandler:^(NSImage *image) {
            image.size = ICON_SIZE;
            tabMenuItem.image = image;
        }];
    } else {
        tabMenuItem.image = [DSFavIconManager sharedInstance].placeholder;
    }
    tabMenuItem.image.size = ICON_SIZE;

    return tabMenuItem;
}

- (void)updateStatusItemToolTip
{
    NSDate *fileModificationDate = [self latestModificationDate];
    if (fileModificationDate != nil) {
        NSString *toolTip = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)\niCloud Last Synced: %@", @""), [self appBundleName], [self appBundleVersion], [self.dateFormatter stringFromDate:fileModificationDate]];
        [self.statusItem setToolTip:toolTip];
    }
}

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

#pragma mark - Launch at login

- (NSURL *)appURL
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)startAtLogin
{
    return [JPLaunchAtLoginManager willStartAtLogin:[self appURL]];
}

- (void)setStartAtLogin:(BOOL)enabled
{
    [self willChangeValueForKey:@"startAtLogin"];
    [JPLaunchAtLoginManager setStartAtLogin:[self appURL] enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}

#pragma mark - Getters

- (NSMenu *)menu
{
    if (!_menu) {
        _menu = [[NSMenu alloc] init];
    }
    return _menu;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
        _dateFormatter.doesRelativeDateFormatting = YES;
    }
    return _dateFormatter;
}

@end
