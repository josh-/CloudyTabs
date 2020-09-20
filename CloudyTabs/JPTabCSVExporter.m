//
//  JPTabCSVExporter.m
//  CloudyTabs
//
//  Created by Josh Parnham on 13/9/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import "JPTabCSVExporter.h"

#import "CHCSVParser.h"

@implementation JPTabCSVExporter

+ (void)exportTabs:(NSArray<NSDictionary *> *)tabData deviceName:(NSString *)deviceName {
    NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:temporaryFilePath];
    [writer writeLineOfFields:@[@"URL", @"Title"]];
    
    for (NSDictionary *tab in tabData) {
        [writer writeLineWithDictionary:tab];
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.nameFieldStringValue = [deviceName stringByAppendingString:@".csv"];
    savePanel.allowedFileTypes = @[@"csv"];
    [savePanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *url = savePanel.URL;
            
            if (url == nil) {
                return;
            }
            
            NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath isDirectory:NO];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager copyItemAtURL:temporaryFileURL toURL:url error:nil];
        }
    }];
}

@end
