//
//  JPLaunchAtLoginManager.h
//  CloudyTabs
//
//  Based on a modified version of this StackOverflow answer - http://stackoverflow.com/a/2318004/446039
//

@interface JPLaunchAtLoginManager : NSObject

+ (BOOL)willStartAtLogin:(NSURL *)itemURL;
+ (void)setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

@end
