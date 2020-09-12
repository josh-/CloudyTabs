//
//  JPAppDelegate.m
//  CloudyTabs
//
//  Created by Josh Parnham on 3/03/2014.
//  Copyright (c) 2014 Josh Parnham. All rights reserved.
//

#import "JPAppDelegate.h"

#import <Sparkle/Sparkle.h>

#import "JPLaunchAtLoginManager.h"
#import "JPUserDefaultsController.h"
#import "DSFavIconManager.h"

#import "JPCloudTabsDBReader.h"
#import "JPReadingListReader.h"

#import "JPLoadingMenuItem.h"
#import "NSURL+Extensions.h"
#import "NSMenuItem+ItemCreation.h"

@interface JPAppDelegate ()

@property (strong, nonatomic) NSDate *lastUpdateDate;

@property (strong, nonatomic) JPCloudTabsDBReader *cloudTabsDBReader;
@property (strong, nonatomic) JPReadingListReader *readingListReader;

@property (strong, nonatomic) NSArray *tabData;
@property (strong, nonatomic) NSArray *readingListItems;

@end

NSString *const HELPER_BUNDLE_ID = @"com.joshparnham.CloudyTabsHelper";

@implementation JPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.cloudTabsDBReader = [[JPCloudTabsDBReader alloc] init];
    self.readingListReader = [[JPReadingListReader alloc] init];
    
    [DSFavIconManager sharedInstance].placeholder = [NSImage imageNamed:@"Globe"];
    [JPUserDefaultsController registerUserDefaults];
    
    [self createStatusItem];
    [self updateMenu];
    [self setupQueue];
    [self setupSparkle];
    [self updateUserInterface];
}

#pragma mark - Menu actions

- (void)tabMenuItemClicked:(id)sender
{
    NSURL *URL = [(NSMenuItem *)sender representedObject];
    
    if ([NSEvent modifierFlags] == NSEventModifierFlagCommand) {
        [[NSWorkspace sharedWorkspace] openURLs:@[URL] withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
    else if ([NSEvent modifierFlags] == NSEventModifierFlagOption) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        
        NSURL *URL = [[self.menu highlightedItem] representedObject];
        if (![pasteboard writeObjects:@[URL]]) {
            NSLog(@"Unable to copy URL to the pasteboard.");
        }
    }
    else {
        [[NSWorkspace sharedWorkspace] openURL:URL];
    }
}

- (void)deviceMenuItemClicked:(id)sender
{
    NSUInteger launch;
    if ([NSEvent modifierFlags] == NSEventModifierFlagCommand) {
        launch = NSWorkspaceLaunchWithoutActivation;
    }
    else {
        launch = NSWorkspaceLaunchDefault;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *deviceID = [(NSMenuItem *)sender representedObject];
        NSArray *tabs = self.tabData[[self.tabData indexOfObjectPassingTest:^BOOL(id  _Nonnull dictionary, NSUInteger index, BOOL * _Nonnull stop) {
            return [dictionary[@"DeviceName"] isEqualToString:deviceID];
        }]];

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

- (void)promptFullDiskAccess:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Enable Full Disk Access", @"");
    alert.informativeText = NSLocalizedString(@"CloudyTabs requies Full Disk Access to access your Safari data. Click \"Enable\" to open System Prefences and then click the checkbox next to \"CloudyTabs\".", @"");
    alert.alertStyle = NSAlertStyleInformational;
    
    [alert addButtonWithTitle:NSLocalizedString(@"Enable", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    
    NSInteger alertResult = [alert runModal];
    if (alertResult == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL privacyAllFilesSystemPreferencesURL]];
    }
}

#pragma mark - Queue delegate

-(void)VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath
{
    [self.readingListReader fetchReadingListModificationDate:^(NSDate *readingListModificationDate) {
        // Only update menu if the data has been updated since last refresh
        BOOL newReadingListData = [readingListModificationDate laterDate:self.lastUpdateDate] == readingListModificationDate;
        if (newReadingListData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateUserInterface];
            });
        }
    }];
     
    [self.cloudTabsDBReader fetchDatabaseModificationDate:^(NSDate *cloudTabsModificationDate) {
        // Only update menu if the data has been updated since last refresh
        BOOL newCloudTabData = [cloudTabsModificationDate laterDate:self.lastUpdateDate] == cloudTabsModificationDate;
        if (newCloudTabData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateUserInterface];
            });
        }
    }];
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

    [queue addPath:[self.cloudTabsDBReader cloudTabsDBFile] notifyingAbout:VDKQueueNotifyDefault];
    [queue addPath:[self.readingListReader syncedBookmarksFile] notifyingAbout:VDKQueueNotifyDefault];

    queue.delegate = self;
}

- (void)updateUserInterface
{
    [self.cloudTabsDBReader fetchTabData:^(NSArray<NSDictionary *> *tabData) {
        self.tabData = tabData;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMenu];
        });
    }];
    
    [self.readingListReader fetchReadingListItems:^(NSArray *readingListItems) {
        self.readingListItems = readingListItems;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMenu];
        });
    }];
}

- (BOOL)requiresFullDiskAccess
{
    return ![self.cloudTabsDBReader permissionsToReadFile];
}

- (void)createStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setImage:[NSImage imageNamed:@"StatusIcon"]];
    [self.statusItem setMenu:self.menu];
    [self.statusItem setEnabled:YES];
    
    NSString *toolTip = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", @""), [self appBundleName], [self appBundleVersion]];
    self.statusItem.toolTip = toolTip;
}

- (void)updateMenu
{
    [self.menu removeAllItems];
    
    if (self.tabData) {
        NSMenu *devicesMenu = [[NSMenu alloc] initWithTitle:@"Devices"];
        [devicesMenu setAutoenablesItems:NO];
        
        for (NSDictionary *deviceTabs in self.tabData) {
            
            // Hide devices that don't have any tabs
            if (((NSArray *)deviceTabs[@"Tabs"]).count <= 0) {
                continue;
            }
            
            // Hide tabs from Mac where CloudyTabs is currently running on, unless the user has expliclty set the user default
            if ([JPUserDefaultsController shouldListAllDevices] == false && [[NSHost currentHost].localizedName isEqualToString:deviceTabs[@"DeviceName"]]) {
                continue;
            }
            
            // Add a seperator if this device isn't the first in the list
            if (self.menu.itemArray.count > 0) {
                NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
                [self.menu addItem:seperatorItem];
            }
            
            NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:deviceTabs[@"DeviceName"] action:nil keyEquivalent:@""];
            deviceMenuItem.enabled = NO;
            [self.menu addItem:deviceMenuItem];
            
            // Add device to "Open All Tabs From" submenu
            NSString *localisedTabCount = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:((NSArray *)deviceTabs[@"Tabs"]).count] numberStyle:NSNumberFormatterNoStyle];
            NSString *openAllTabsFromDeviceMenuItemTitle = [NSString stringWithFormat:@"%@ (%@)", deviceTabs[@"DeviceName"], localisedTabCount];
            NSMenuItem *openAllTabsFromDeviceMenuItem = [[NSMenuItem alloc] initWithTitle:openAllTabsFromDeviceMenuItemTitle action:@selector(deviceMenuItemClicked:) keyEquivalent:@""];
            openAllTabsFromDeviceMenuItem.representedObject = deviceTabs[@"DeviceName"];
            if ([deviceTabs[@"Tabs"] count] < 1) {
                [openAllTabsFromDeviceMenuItem setEnabled:NO];
            }
            [devicesMenu addItem:openAllTabsFromDeviceMenuItem];

            for (NSDictionary *tabDictionary in deviceTabs[@"Tabs"]) {
                [self.menu addItem:[NSMenuItem menuItemWithTitle:tabDictionary[@"Title"] URLPath:tabDictionary[@"URL"] action:@selector(tabMenuItemClicked:)]];
            }
        }
                
        if ([self readingListItems].count > 0) {
            if (self.menu.itemArray.count > 0) {
                [self.menu addItem:[NSMenuItem separatorItem]];
            }
    
            NSMenuItem *readingListTitle = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reading List", @"") action:nil keyEquivalent:@""];
            readingListTitle.enabled = NO;
            [self.menu addItem:readingListTitle];
    
            for (NSDictionary *bookmarkDictionary in self.readingListItems) {
                [self.menu addItem:[NSMenuItem menuItemWithTitle:bookmarkDictionary[@"URIDictionary"][@"title"] URLPath:bookmarkDictionary[@"URLString"] action:@selector(tabMenuItemClicked:)]];
            }
        }
        
        if (self.menu.itemArray.count > 0) {
            [self.menu addItem:[NSMenuItem separatorItem]];
        }
        
        if (self.tabData.count >= 1) {
            NSMenuItem *openAllTabsMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open All Tabs From", @"") action:nil keyEquivalent:@""];
            [self.menu addItem:openAllTabsMenu];
            [openAllTabsMenu setSubmenu:devicesMenu];
            [openAllTabsMenu setEnabled:(devicesMenu.itemArray.count >= 1)];
        }
    } else {
        if ([self requiresFullDiskAccess]) {
            NSMenuItem *fullDiskAccessItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Requires Full Disk Access…", @"") action:@selector(promptFullDiskAccess:) keyEquivalent:@""];
            [self.menu addItem:fullDiskAccessItem];
            [self.menu addItem:[NSMenuItem separatorItem]];
        } else {
            JPLoadingMenuItem *loadingMenuItem = [[JPLoadingMenuItem alloc] initWithTitle:@"Loading" action:nil keyEquivalent:@""];
            [self.menu addItem:loadingMenuItem];
        }
    }
    
    NSMenuItem *openAtLoginItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Launch %@ At Login", @""), [self appBundleName]] action:@selector(openAtLoginToggled:) keyEquivalent:@""];
    openAtLoginItem.state = [self startAtLogin];
    [self.menu addItem:openAtLoginItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), [self appBundleName]] action:@selector(quit:) keyEquivalent:@"q"];
    [self.menu addItem:quitMenuItem];
    
    self.lastUpdateDate = [NSDate date];
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
    return [JPLaunchAtLoginManager willStartAtLogin:HELPER_BUNDLE_ID];
}

- (void)setStartAtLogin:(BOOL)enabled
{
    [self willChangeValueForKey:@"startAtLogin"];
    [JPLaunchAtLoginManager setStartAtLogin:HELPER_BUNDLE_ID enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}

#pragma mark - Menu delegate

- (void)menuWillOpen:(NSMenu *)menu
{
    [self updateUserInterface];
}

#pragma mark - Getters

- (NSMenu *)menu
{
    if (!_menu) {
        _menu = [[NSMenu alloc] init];
        _menu.delegate = self;
    }
    return _menu;
}

@end
