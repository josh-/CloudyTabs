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
#import "DSFavIconManager.h"

#import "JPTabsContainer.h"
#import "JPSyncedPreferencesReader.h"
#import "JPCloudTabsDBReader.h"

@interface JPAppDelegate ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSDate *lastUpdateDate;

@property (strong, nonatomic) id<JPTabsContainer> tabContainer;

@end

@implementation JPAppDelegate

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
            NSURL *url = [NSURL URLWithString:[tabDictionary[@"URL"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

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
    // Check if the modification date of the syncedPreferences file is later than the date of the last menu update
    NSDate *fileModificationDate = [self.tabContainer modificationDate];
    if ([fileModificationDate laterDate:self.lastUpdateDate] == fileModificationDate) {
        [self updateUserInterface];
    }
    return;
}

#pragma mark - Methods

- (NSString *)appBundleName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (void)setupSparkle
{
    SUUpdater *updater = [[SUUpdater class] sharedUpdater];
    [updater checkForUpdatesInBackground];
}

- (void)setupQueue
{
    VDKQueue *queue = [[VDKQueue alloc] init];
    
    NSString *filePath = [[self.tabContainer class] filePath];
    [queue addPath:filePath notifyingAbout:VDKQueueNotifyDefault];
    [queue setDelegate:self];
}

- (void)createStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setImage:[NSImage imageNamed:@"ToolbarCloudTabsTemplate"]];
    [self.statusItem setMenu:self.menu];
    [self.statusItem setEnabled:YES];
}

- (void)updateUserInterface
{
    [self updateMenu];
    [self updateStatusItemToolTip];
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
        
        // Hide tabs from Mac where CloudyTabs is currently running on
        // TODO: Add localised menu preference for the following
        BOOL hideTabsOfCurrentDevice = YES;
        if (hideTabsOfCurrentDevice) {
            if ([[NSHost currentHost].localizedName isEqualToString:[self.tabContainer deviceNameForID:deviceID]]) {
                continue;
            }
        }
        
        // Add a seperator if this device isn't the first in the list
        if ([[self.tabContainer deviceIDs] indexOfObject:deviceID] > 0) {
            NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
            [self.menu addItem:seperatorItem];
        }
        
        // Add device to main list of tabs
        NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:[self.tabContainer deviceNameForID:deviceID] action:nil keyEquivalent:@""];
        [self.menu addItem:deviceMenuItem];
        
        // Add device to "Open All Tabs From" submenu
        NSMenuItem *openAllTabsFromDeviceMenuItem = [[NSMenuItem alloc] initWithTitle:[self.tabContainer deviceNameForID:deviceID] action:@selector(deviceMenuItemClicked:) keyEquivalent:@""];
        openAllTabsFromDeviceMenuItem.representedObject = deviceID;
        if ([[self.tabContainer tabsForDeviceID:deviceID] count] < 1) {
            [openAllTabsFromDeviceMenuItem setEnabled:NO];
        }
        [devicesMenu addItem:openAllTabsFromDeviceMenuItem];
        
        for (NSDictionary *tabDictionary in deviceTabs) {
            NSMenuItem *tabMenuItem = [[NSMenuItem alloc] initWithTitle:tabDictionary[@"Title"] action:@selector(tabMenuItemClicked:) keyEquivalent:@""];
            
            NSString *URL = tabDictionary[@"URL"];
            NSURL *encodedURL = nil;
            
            // See dot point 4 under "NSURL Deprecations" in "Foundation Release Notes for OS X v10.11"
            
            if ([NSURL respondsToSelector:@selector(URLWithDataRepresentation:relativeToURL:)]) {
                // Modern NSURL API available
                encodedURL = [NSURL URLWithDataRepresentation:[URL dataUsingEncoding:NSUTF8StringEncoding] relativeToURL:nil];
            }
            else {
                // Modern NSURL API not available, fall back to CoreFoundation implementation
                NSData *urlData = [URL dataUsingEncoding:NSUTF8StringEncoding];
                CFURLRef urlRef = CFURLCreateWithBytes(kCFAllocatorSystemDefault, (const UInt8 *)urlData.bytes, urlData.length, kCFStringEncodingUTF8, NULL);
                if (!urlRef) {
                    // Fallback to using ISO Latin encoding
                    urlRef = CFURLCreateWithBytes(kCFAllocatorSystemDefault, (const UInt8 *)urlData.bytes, urlData.length, kCFStringEncodingISOLatin1, NULL);
                }
                encodedURL = (__bridge NSURL *)urlRef;
            }
            
            tabMenuItem.representedObject = encodedURL;
            tabMenuItem.toolTip = encodedURL.relativeString;
            
            __block NSImage *image = [[DSFavIconManager sharedInstance] iconForURL:tabMenuItem.representedObject downloadHandler:^(NSImage *icon) {
                icon.size = NSMakeSize(19, 19);
                [tabMenuItem setImage:icon];
            }];
            image.size = NSMakeSize(19, 19);
            [tabMenuItem setImage:image];
            
            [self.menu addItem:tabMenuItem];
        }
    }
    
    NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
    [self.menu addItem:seperatorItem];
    
    if ([self.tabContainer deviceIDs].count > 1) {
        NSMenuItem *openAllTabsMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open All Tabs From", @"") action:nil keyEquivalent:@""];
        [self.menu addItem:openAllTabsMenu];
        [openAllTabsMenu setSubmenu:devicesMenu];
    }
    
    NSMenuItem *openAtLoginItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Launch %@ At Login", @""), [self appBundleName]] action:@selector(openAtLoginToggled:) keyEquivalent:@""];
    [self.menu addItem:openAtLoginItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), [self appBundleName]] action:@selector(quit:) keyEquivalent:@"q"];
    [self.menu addItem:quitMenuItem];
    
    self.lastUpdateDate = [NSDate date];
}

- (void)updateStatusItemToolTip
{
    NSDate *fileModificationDate = [self.tabContainer modificationDate];
    if (fileModificationDate != nil) {
        NSString *toolTip = [NSString stringWithFormat:NSLocalizedString(@"%@\niCloud Last Synced: %@", @""), [self appBundleName], [self.dateFormatter stringFromDate:fileModificationDate]];
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
