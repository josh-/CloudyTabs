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
#import "DSFavIconManager.h"

@interface JPAppDelegate ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

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
    
    [self updateMenu];
    [self updateStatusItemToolTip];

    // Watch the com.apple.Safari syncedpreference for changes
    VDKQueue *queue = [[VDKQueue alloc] init];
    [queue addPath:[self syncedPreferencesPath] notifyingAbout:VDKQueueNotifyAboutWrite];
    [queue setDelegate:self];
    
    // Set the favicon placeholder
    [DSFavIconManager sharedInstance].placeholder = [NSImage imageNamed:@"BookmarksDragImage"];
    
    // Setup Sparkle
    SUUpdater *updater = [[SUUpdater class] sharedUpdater];
    [updater checkForUpdatesInBackground];
}

#pragma mark - Menu actions

- (void)tabMenuItemClicked:(id)sender
{
    NSURL *URL = [NSURL URLWithString:[(NSMenuItem *)sender representedObject]];
    
    if ([NSEvent modifierFlags] == NSCommandKeyMask) {
        [[NSWorkspace sharedWorkspace] openURLs:@[URL] withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
    else {
        [[NSWorkspace sharedWorkspace] openURL:URL];
    }
}

- (void)deviceMenuItemClicked:(id)sender
{
    NSArray *tabs = [self tabsForDeviceID:[(NSMenuItem *)sender representedObject]];
    
    NSMutableArray *tabURLs = [[NSMutableArray alloc] init];
    
    for (NSDictionary *tabDictionary in tabs) {
        [tabURLs addObject:[NSURL URLWithString:tabDictionary[@"URL"]]];
    }
         
    NSUInteger launch;
    if ([NSEvent modifierFlags] == NSCommandKeyMask) {
        launch = NSWorkspaceLaunchWithoutActivation;
    }
    else {
        launch = NSWorkspaceLaunchDefault;
    }
    
    [[NSWorkspace sharedWorkspace] openURLs:tabURLs withAppBundleIdentifier:nil options:launch additionalEventParamDescriptor:nil launchIdentifiers:nil];
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

-(void) VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath;
{
    [self updateMenu];
    [self updateStatusItemToolTip];
}

#pragma mark - Methods

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
    
    return [dictionary[@"values"] allKeys];
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
    
    for (NSString *deviceID in [self deviceIDs]) {
        
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
        [devicesMenu addItem:openAllTabsFromDeviceMenuItem];
        
        for (NSDictionary *tabDictionary in [self tabsForDeviceID:deviceID]) {
            
            NSMenuItem *tabMenuItem = [[NSMenuItem alloc] initWithTitle:tabDictionary[@"Title"] action:@selector(tabMenuItemClicked:) keyEquivalent:@""];
            
            tabMenuItem.representedObject = tabDictionary[@"URL"];
            
            __block NSImage *image = [[DSFavIconManager sharedInstance] iconForURL:[NSURL URLWithString:tabMenuItem.representedObject] downloadHandler:^(NSImage *icon) {
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
    
    NSMenuItem *openAllTabsMenu = [[NSMenuItem alloc] initWithTitle:@"Open All Tabs From" action:nil keyEquivalent:@""];
    [self.menu addItem:openAllTabsMenu];
    [openAllTabsMenu setSubmenu:devicesMenu];
    
    NSMenuItem *openAtLoginItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Launch %@ At Login", [self appBundleName]] action:@selector(openAtLoginToggled:) keyEquivalent:@""];
    [self.menu addItem:openAtLoginItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Quit %@", [self appBundleName]] action:@selector(quit:) keyEquivalent:@""];
    [self.menu addItem:quitMenuItem];
}

- (void)updateStatusItemToolTip
{
    NSString *toolTip = [NSString stringWithFormat:@"%@\nChanges Last Detected: %@", [self appBundleName], [self.dateFormatter stringFromDate:[self syncedPreferenceModificationDate]]];
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
