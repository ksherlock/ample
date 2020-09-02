//
//  PreferencesWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/31/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()
@property (weak) IBOutlet NSTextField *pathField;

@end

@implementation PreferencesWindowController

-(NSString *)windowNibName {
    return @"Preferences";
}

- (void)windowDidLoad {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self validateMamePath: [defaults stringForKey: kMamePath]];
    
}

-(void)validateMamePath: (NSString *)path {
    NSFileManager * fm = [NSFileManager defaultManager];

    if ([path length] == 0 || [fm isExecutableFileAtPath: path]) {
        [_pathField setTextColor: [NSColor blackColor]];
    } else {
        [_pathField setTextColor: [NSColor redColor]];
    }
}

- (IBAction)pathChanged:(id)sender {

    NSString *path = [sender stringValue];
    
    [self validateMamePath: path];

}


@end
