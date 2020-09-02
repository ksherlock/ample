//
//  AppDelegate.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//
#import "Ample.h"
#import "AppDelegate.h"
#import "LaunchWindowController.h"
#import "PreferencesWindowController.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *installWindow;

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
    


    if ([self installMameComponents]) {
        [self displayLaunchWindow];
    }

}

-(void)displayLaunchWindow {

    if (!_launcher) {
        _launcher = [LaunchWindowController new];
    }
    [_launcher showWindow: nil];
}

-(BOOL)installMameComponents {
    
    /* install the mame data components. */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *sd = SupportDirectory();

    NSURL *ample_url = [sd URLByAppendingPathComponent: @"Ample.plist"];
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfURL: ample_url];
    
    NSDate *oldDate = [d objectForKey: kMameComponentsDate];
    NSDate *newDate = [defaults objectForKey: kMameComponentsDate];
    if (![newDate isKindOfClass: [NSDate class]])
        newDate = nil;
    
    if (!newDate) return YES; //????
    if (oldDate && [oldDate compare: newDate] >= 0) return YES;

    NSString *path = [bundle pathForResource: @"mame-data" ofType: @"tgz"];
    if (!path) return YES; // Ample Lite?

    
    NSWindow *win = _installWindow;
    [win makeKeyAndOrderFront: nil];
    NSTask *task = [NSTask new];
    NSArray *argv = @[
        @"xfz",
        path
    ];
    [task setExecutableURL: [NSURL fileURLWithPath: @"/usr/bin/tar"]];
    [task setArguments: argv];
    [task setCurrentDirectoryURL: sd];
    
    
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
    [task setTerminationHandler: ^(NSTask *task){
       
        dispatch_after(when, dispatch_get_main_queue(), ^{
  
            int st = [task terminationStatus];

            if (st) {
                NSAlert *alert = [NSAlert new];
                [alert setMessageText: @"An error occurred extracting MAME components"];
                [alert runModal];
                [win close];
                return;
            }
            
            if (d) {
                [d setObject: newDate forKey: kMameComponentsDate];
                [d writeToURL: ample_url atomically: YES];
            } else {
                [@{ kMameComponentsDate: newDate } writeToURL: ample_url atomically: YES];
            }
            [win close];
            [self displayLaunchWindow];
        });
        
    }];
    [task launch];

    return NO;
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
        _prefs = [PreferencesWindowController new];
    }
    [_prefs showWindow: sender];
}


@end
