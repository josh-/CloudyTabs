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

@interface JPAppDelegate ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSDate *lastUpdateDate;

@end

@implementation JPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
//    [self.statusItem setTitle:@"☁︎"];
    [self.statusItem setImage:[NSImage imageNamed:@"ToolbarCloudTabsTemplate"]];
    [self.statusItem setMenu:self.menu];
    [self.statusItem setEnabled:YES];
    
    // Set the favicon placeholder
    [DSFavIconManager sharedInstance].placeholder = [NSImage imageNamed:@"BookmarksDragImage"];

    [self updateMenu];
    [self updateStatusItemToolTip];

    // Watch the com.apple.Safari syncedpreference for changes
    VDKQueue *queue = [[VDKQueue alloc] init];
    [queue addPath:[self syncedPreferencesPath] notifyingAbout:VDKQueueNotifyDefault];
    [queue setDelegate:self];
    
    // Setup Sparkle
    SUUpdater *updater = [[SUUpdater class] sharedUpdater];
    [updater checkForUpdatesInBackground];
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

        NSArray *tabs = [self tabsForDeviceID:[(NSMenuItem *)sender representedObject]];

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
    if ([[self syncedPreferenceModificationDate] laterDate:self.lastUpdateDate] == [self syncedPreferenceModificationDate]) {
        [self updateUserInterface];
    }
    return;
}

#pragma mark - Methods

- (void)updateUserInterface
{
    [self updateMenu];
    [self updateStatusItemToolTip];
}

- (NSString *)syncedPreferencesPath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *syncedPreferencesPath = [paths[0] stringByAppendingPathComponent:@"SyncedPreferences"];
    
    return syncedPreferencesPath;
}

- (NSDictionary *)syncedPreferenceDictionary
{
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:[[self syncedPreferencesPath] stringByAppendingPathComponent:@"com.apple.Safari.plist"]];
    
    return dictionary;
}

- (NSArray *)deviceIDs
{
    NSDictionary *dictionary = [self syncedPreferenceDictionary];
    
    NSMutableArray *deviceIDs = [[NSMutableArray alloc] init];

    for (NSString *deviceID in [dictionary[@"values"] allKeys]) {
        // Hide devices that haven't had activity in the last week (604800 = 7×24×60×60 = one week in seconds)
        if ([dictionary[@"values"][deviceID][@"value"][@"LastModified"] timeIntervalSinceNow] < 604800) {
            [deviceIDs addObject:deviceID];
        }
    }
    return deviceIDs;
}

- (NSString *)deviceNameForID:(NSString *)deviceID
{
    NSDictionary *dictionary = [self syncedPreferenceDictionary];
    
    return dictionary[@"values"][deviceID][@"value"][@"DeviceName"];
}

- (NSArray *)tabsForDeviceID:(NSString *)deviceID
{
    NSDictionary *dictionary = [self syncedPreferenceDictionary];
    
    return dictionary[@"values"][deviceID][@"value"][@"Tabs"];
}

- (NSDate *)syncedPreferenceModificationDate
{
    NSURL *preferencesURL = [NSURL fileURLWithPath:[[self syncedPreferencesPath] stringByAppendingPathComponent:@"com.apple.Safari.plist"]];
    
    NSDate *modificationDate;
    if ([preferencesURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil]) {
        return modificationDate;
    }
    else {
        return nil;
    }
}

- (NSString *)appBundleName
{
    return [[[NSBundle mainBundle] infoDictionary]  objectForKey:@"CFBundleName"];
}

- (void)updateMenu
{
    [self.menu removeAllItems];
    
    NSMenu *devicesMenu = [[NSMenu alloc] initWithTitle:@"Devices"];
    [devicesMenu setAutoenablesItems:NO];
    
    for (NSString *deviceID in [self deviceIDs]) {
        
        NSArray *arrayOfTabs = [self tabsForDeviceID:deviceID];
        
        // hide devices that don't have any tabs
        if (arrayOfTabs.count <= 0) {
            continue;
        }
        
        // hide tabs from Mac where CloudyTabs is currently running on
        BOOL hideTabsOfCurrentDevice = YES; // didn't want to add a menu item for this setting until maybe there is a proper preferences window
        if (hideTabsOfCurrentDevice) {
            if ([[NSHost currentHost].localizedName isEqualToString:[self deviceNameForID:deviceID]]) {
                continue;
            }
        }
        
        // Add a seperator if this device isn't the first in the list
        if ([[self deviceIDs] indexOfObject:deviceID] > 0) {
            NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
            [self.menu addItem:seperatorItem];
        }
        
        // Add device to main list of tabs
        NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:[self deviceNameForID:deviceID] action:nil keyEquivalent:@""];
        [self.menu addItem:deviceMenuItem];
        
        // Add device to "Open All Tabs From" submenu
        NSMenuItem *openAllTabsFromDeviceMenuItem = [[NSMenuItem alloc] initWithTitle:[self deviceNameForID:deviceID] action:@selector(deviceMenuItemClicked:) keyEquivalent:@""];
        openAllTabsFromDeviceMenuItem.representedObject = deviceID;
        if ([[self tabsForDeviceID:deviceID] count] < 1) {
            [openAllTabsFromDeviceMenuItem setEnabled:NO];
        }
        [devicesMenu addItem:openAllTabsFromDeviceMenuItem];
        
        for (NSDictionary *tabDictionary in arrayOfTabs) {
            
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
    
    NSMenuItem *openAllTabsMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open All Tabs From", @"") action:nil keyEquivalent:@""];
    [self.menu addItem:openAllTabsMenu];
    [openAllTabsMenu setSubmenu:devicesMenu];
    
    NSMenuItem *openAtLoginItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Launch %@ At Login", @""), [self appBundleName]] action:@selector(openAtLoginToggled:) keyEquivalent:@""];
    [self.menu addItem:openAtLoginItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), [self appBundleName]] action:@selector(quit:) keyEquivalent:@"q"];
    [self.menu addItem:quitMenuItem];
    
    self.lastUpdateDate = [NSDate date];
}

- (void)updateStatusItemToolTip
{
    NSString *toolTip = [NSString stringWithFormat:NSLocalizedString(@"%@\niCloud Last Synced: %@", @""), [self appBundleName], [self.dateFormatter stringFromDate:[self syncedPreferenceModificationDate]]];
    [self.statusItem setToolTip:toolTip];
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
