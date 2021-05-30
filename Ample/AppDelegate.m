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
#import "DownloadWindowController.h"
#import "DiskImagesWindowController.h"
#import "CheatSheetWindowController.h"
#import "Transformers.h"

#import "LogWindowController.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *installWindow;

@end

@implementation AppDelegate {
    NSWindowController *_prefs;
    NSWindowController *_launcher;
    NSWindowController *_downloader;
    NSWindowController *_diskImages;
    NSWindowController *_cheatSheet;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path;
    NSDictionary *dict;
    
    
    RegisterTransformers();
    
    path = [bundle pathForResource: @"Defaults" ofType: @"plist"];
    dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    if (dict)
    {
        [[NSUserDefaults standardUserDefaults] registerDefaults: dict];
    }
    


    _diskImages = [DiskImagesWindowController sharedInstance]; //[DiskImagesWindowController new];

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
    if (@available(macOS 10.13, *)) {
        [task setExecutableURL: [NSURL fileURLWithPath: @"/usr/bin/tar"]];
        [task setCurrentDirectoryURL: sd];
    } else {
        [task setLaunchPath:  @"/usr/bin/tar"];
        [task setCurrentDirectoryPath: SupportDirectoryPath()];
    }
    [task setArguments: argv];

    
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
            [self displayROMS: nil];
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


-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    
    NSString *ext = [[filename pathExtension] lowercaseString];
    
    if ([ext isEqualToString: @"vgm"] || [ext isEqualToString: @"vgz"]) {
        // run mame...
        NSArray *args = @[ @"vgmplay", @"-window", @"-nomax", @"-skip_gameinfo", @"-quik", filename ];
        
        [LogWindowController controllerForArgs: args];
    }
    return NO;
}


#pragma mark - IBActions


- (IBAction)displayPreferences:(id)sender {
    if (!_prefs) {
        _prefs = [PreferencesWindowController new];
    }
    [_prefs showWindow: sender];
}


- (IBAction)displayROMS:(id)sender {
    if (!_downloader) {
        _downloader = [DownloadWindowController sharedInstance];
    }
    [_downloader showWindow: sender];
}

- (IBAction)displayRecentDiskImages:(id)sender {
    if (!_diskImages) {
        _diskImages = [DiskImagesWindowController sharedInstance];
    }
    [_diskImages showWindow: sender];
}

- (IBAction)displayCheatSheet:(id)sender {
    if (!_cheatSheet) {
        _cheatSheet = [CheatSheetWindowController new];
    }
    [_cheatSheet showWindow: sender];
}

- (IBAction)displaySupportDirectory:(id)sender {
    NSURL *url = SupportDirectory();
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws openURL: url];
}
- (IBAction)mameDocumentation:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSURL *url = [NSURL URLWithString: @"https://docs.mamedev.org"];
    [ws openURL: url];
}

- (IBAction)mameAppleWiki:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSURL *url = [NSURL URLWithString: @"https://wiki.mamedev.org/index.php/Driver:Apple_II"];
    [ws openURL: url];
}

- (IBAction)mameMac68kWiki:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSURL *url = [NSURL URLWithString: @"https://wiki.mamedev.org/index.php/Driver:Mac_68K"];
    [ws openURL: url];
}




@end
