//
//  AppDelegate.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "AppDelegate.h"
#import "SlotViewController.h"
#import "MediaViewController.h"
#import "LaunchWindowController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate {
    NSWindowController *_prefs;
    NSWindowController *_launcher;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path;
    NSDictionary *dict;
    
    
    path = [bundle pathForResource: @"Defaults" ofType: @"plist"];
    dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    if (dict)
    {
        [[NSUserDefaults standardUserDefaults] registerDefaults: dict];
    }
    
    _launcher = [LaunchWindowController new];
    [_launcher showWindow: nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}




#pragma mark - IBActions


- (IBAction)displayPreferences:(id)sender {
    if (!_prefs) {
        _prefs = [[NSWindowController alloc] initWithWindowNibName: @"Preferences"];
    }
    [_prefs showWindow: sender];
}


@end
