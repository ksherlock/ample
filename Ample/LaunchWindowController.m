//
//  LaunchWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "LaunchWindowController.h"
#import "MediaViewController.h"
#import "SlotViewController.h"
#import "MachineViewController.h"
#import "LogWindowController.h"

#import "AutocompleteControl.h"
#import "SoftwareList.h"

#include <sys/stat.h>
#include <wctype.h>

static NSString *kMyContext = @"kMyContext";
static NSString *kContextMachine = @"kContextMachine";


@interface LaunchWindowController ()
@property (strong) IBOutlet MediaViewController *mediaController;
@property (strong) IBOutlet SlotViewController *slotController;
@property (strong) IBOutlet MachineViewController *machineViewController;

@property (weak) IBOutlet NSView *machineView;
@property (weak) IBOutlet NSView *slotView;
@property (weak) IBOutlet NSView *mediaView;

/* kvo */
@property NSString *commandLine;
@property NSArray *args;

@property NSString *mameMachine;
@property BOOL mameDebug;
@property BOOL mameSquarePixels;
@property BOOL mameMouse;
@property BOOL mameSamples;

@property BOOL mameAVI;
@property BOOL mameWAV;
@property BOOL mameVGM;

@property NSString *mameAVIPath;
@property NSString *mameWAVPath;
@property NSString *mameVGMPath;
@property NSString *mameShareDirectory;

@property NSInteger mameSpeed;

@property BOOL mameBGFX;
@property NSInteger mameBackend;
@property NSInteger mameEffects;


@property NSInteger mameWindowMode;

@property (weak) IBOutlet AutocompleteControl *softwareListControl;
@property SoftwareSet *softwareSet;
@property Software *software;
@end

@interface LaunchWindowController (SoftwareList)

-(void)updateSoftwareList;

@end

@implementation LaunchWindowController

-(NSString *)windowNibName {
    return @"LaunchWindow";
}

-(void)windowWillLoad {
    [self setMameSpeed: 1];
    [self setMameBGFX: YES];
    [self setMameMouse: NO];
    [self setMameSamples: YES];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.


    [_slotView addSubview: [_slotController view]];
    [_mediaView addSubview: [_mediaController view]];
    [_machineView addSubview: [_machineViewController view]];
    

    NSArray *keys = @[
        @"mameMachine", @"mameSquarePixels", @"mameWindowMode",
        @"mameMouse", @"mameSamples",
        @"mameDebug",
        @"mameSpeed",
        @"mameAVI", @"mameAVIPath",
        @"mameWAV", @"mameWAVPath",
        @"mameVGM", @"mameVGMPath",
        @"mameShareDirectory",
        @"mameBGFX", @"mameBackend", @"mameEffects",
        @"software",
    ];
    
    for (NSString *key in keys) {
        [self addObserver: self forKeyPath: key options:0  context: (__bridge void * _Nullable)(kMyContext)];
    }
    

    [_slotController addObserver: self forKeyPath: @"args" options: 0 context: (__bridge void * _Nullable)(kMyContext)];
    [_mediaController addObserver: self forKeyPath: @"args" options: 0 context: (__bridge void * _Nullable)(kMyContext)];

    [_mediaController bind: @"media" toObject: _slotController withKeyPath: @"media" options: 0];
    
    [_machineViewController addObserver: self forKeyPath: @"machine" options: 0 context: (__bridge void * _Nullable)kContextMachine];

    
    [_softwareListControl setMinWidth: 250];
    [_softwareListControl setHidden: YES];
    
    [self buildCommandLine];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if (context == (__bridge void *)kMyContext) {
        [self buildCommandLine];
    } else if (context == (__bridge void *)kContextMachine) {
        NSString *machine = [_machineViewController machine];
        [self setMameMachine: machine];
        [_slotController setMachine: machine];
        [self updateSoftwareList];
        [self buildCommandLine];
    } else {
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}




static NSString * JoinArguments(NSArray *argv, NSString *argv0) {

    static NSCharacterSet *safe = nil;
    static NSCharacterSet *unsafe = nil;

    if (!safe) {
        NSString *str =
            @"%+-./:=_"
            @"0123456789"
            @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        ;
        safe = [NSCharacterSet characterSetWithCharactersInString: str];
        unsafe = [safe invertedSet];
    }
    
    NSMutableString *rv = [NSMutableString new];

    
    //unsigned ix = 0;
    //[rv appendString: @"mame"];
    if (argv0) {
        [rv appendString: argv0];
    } else {
        NSString *path = MamePath();
        path = path ? [path lastPathComponent] : @"mame";
        [rv appendString: path];
    }
    for (NSString *s in argv) {
        [rv appendString: @" "];
        NSUInteger l = [s length];
        
        if (!l) {
            [rv appendString: @"''"];
            continue;
        }
        
        if (!CFStringFindCharacterFromSet((CFStringRef)s, (CFCharacterSetRef)unsafe, CFRangeMake(0, l), 0, NULL)) {
            [rv appendString: s];
            continue;
        }
        
        unichar *buffer = malloc(sizeof(unichar) * l);
        [s getCharacters: buffer range: NSMakeRange(0, l)];

        [rv appendString: @"'"];
        for (NSUInteger i = 0; i < l; ++i) {
            unichar c = buffer[i];
            switch (c) {
                case '\'':
                    [rv appendString: @"\\'"];
                    break;
                case '\\':
                    [rv appendString: @"\\\\"];
                    break;
                case 0x7f:
                    [rv appendString: @"\\177"];
                    break;
                default: {
                    NSString *cc;
                    if (c < 0x20) {
                        cc = [NSString stringWithFormat: @"\\%o", c];
                    } else {
                        cc = [NSString stringWithCharacters: &c length: 1];
                    }
                    [rv appendString: cc];
                    break;
                }
            }
        }
        [rv appendString: @"'"];
        free(buffer);
    }
    return rv;
}

static NSString *ShellQuote(NSString *s) {

    static NSCharacterSet *safe = nil;
    static NSCharacterSet *unsafe = nil;

    if (!safe) {
        NSString *str =
            @"%+-./:=_"
            @"0123456789"
            @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        ;
        safe = [NSCharacterSet characterSetWithCharactersInString: str];
        unsafe = [safe invertedSet];
    }
        
    NSUInteger l = [s length];
    
    if (!l) {
        return @"''";
    }
    
    if (!CFStringFindCharacterFromSet((CFStringRef)s, (CFCharacterSetRef)unsafe, CFRangeMake(0, l), 0, NULL)) {
        return s;
    }

    NSMutableString *rv = [NSMutableString new];

    unichar *buffer = malloc(sizeof(unichar) * l);
    [s getCharacters: buffer range: NSMakeRange(0, l)];

    [rv appendString: @"'"];
    for (NSUInteger i = 0; i < l; ++i) {
        unichar c = buffer[i];
        switch (c) {
            case '\'':
                [rv appendString: @"\\'"];
                break;
            case '\\':
                [rv appendString: @"\\\\"];
                break;
            case 0x7f:
                [rv appendString: @"\\177"];
                break;
            default: {
                NSString *cc;
                if (c < 0x20) {
                    cc = [NSString stringWithFormat: @"\\%o", c];
                } else {
                    cc = [NSString stringWithCharacters: &c length: 1];
                }
                [rv appendString: cc];
                break;
            }
        }
    }
    [rv appendString: @"'"];
    free(buffer);
    return rv;
}


-(void)buildCommandLine {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!_mameMachine) {
        [self setCommandLine: @""];
        return;
    }

    NSMutableArray *argv = [NSMutableArray new];

    //[argv addObject: @"mame"];
    [argv addObject: _mameMachine];
    
    if (_software) {
        // todo -- need to include source as well.
        NSString *name = [_software name];
        if (![_softwareSet nameIsUnique: name])
            name = [_software fullName];
        [argv addObject: name];
    }

    // -confirm_quit?
    [argv addObject: @"-skip_gameinfo"];

    
    if (_mameMouse)
        [argv addObject: @"-mouse"]; // capture the mouse cursor when over the window.

    if (!_mameSamples)
        [argv addObject: @"-nosamples"];
    
    if (_mameDebug) [argv addObject: @"-debug"];


    
    /*
     * -window -nomax uses a 4:3 aspect ratio - ie, height = width * 3 / 4 (since height is always the limiting factor)
     * for square pixels, should pass the true size and true aspect ratio.
     */

    NSSize screen = [_slotController resolution];
    switch(_mameWindowMode) {
        case 0: // full screen;
            // no uneven stretch doesn't do anything in full-screen mode.
            break;
        case 1: // 1x
            // make the command-line a bit shorter and more pleasant.
            if (!_mameSquarePixels) {
                [argv addObject: @"-window"];
                [argv addObject: @"-nomax"];
                 break;
            }

            // drop through.
        case 2: // 2x
        case 3: // 3x

            if (_mameSquarePixels) {
                //              NSString *aspect = [NSString stringWithFormat: @"%u:%u", (unsigned)screen.width, (unsigned)screen.height];
                //              [argv addObject: @"-aspect"];
                //              [argv addObject: aspect];
                [argv addObject: @"-nounevenstretch"];
            } else {
                screen.height = round(screen.width * 3 / 4);
            }
            
            [argv addObject: @"-window"];
            NSString *res = [NSString stringWithFormat: @"%ux%u",
                   (unsigned)(_mameWindowMode * screen.width),
                   (unsigned)(_mameWindowMode * screen.height)
                   ];

            [argv addObject: @"-resolution"];
            [argv addObject: res];
            break;
    }



    if (_mameBGFX) {
        if (_mameBackend) {
            static NSString *Names[] = {
                @"-",
                @"metal",
                @"opengl",
            };
            [argv addObject: @"-bgfx_backend"];
            [argv addObject: Names[_mameBackend]];
        }
        if (_mameEffects) {
            static NSString *Names[] = {
                @"-",
                @"unfiltered",
                @"hlsl",
                @"crt-geom",
                @"crt-geom-deluxe",
                @"lcd-grid",
            };
            [argv addObject: @"-bgfx_screen_chains"];
            [argv addObject: Names[_mameEffects]];
        }

    } else {
        [argv addObject: @"-video"];
        [argv addObject: @"soft"];
    }


    // -speed n
    // -scale n
    
    NSArray *tmp;
    tmp = [_slotController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }

    tmp = [_mediaController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }

    if (_mameSpeed < 0) {
        [argv addObject: @"-nothrottle"];
    } else if (_mameSpeed > 1) {
        [argv addObject: @"-speed"];
        [argv addObject: [NSString stringWithFormat: @"%d", (int)_mameSpeed]];
    }
    
    // audio video.
 
    if (_mameAVI && [_mameAVIPath length]) {
        [argv addObject: @"-aviwrite"];
        [argv addObject: _mameAVIPath];
    }

    if (_mameWAV && [_mameWAVPath length]) {
         [argv addObject: @"-wavwrite"];
         [argv addObject: _mameWAVPath];
     }

    // vgm only valid for custom mame.
    if (![defaults boolForKey: kUseCustomMame]) {
        if (_mameVGM && [_mameVGMPath length]) {
            [argv addObject: @"-vgmwrite"];
            [argv addObject: _mameVGMPath];
        }
    }
    
    if (_mameShareDirectory && [_mameShareDirectory length]) {
        [argv addObject: @"-share_directory"];
        [argv addObject: _mameShareDirectory];
    }
    
    
    [self setCommandLine: JoinArguments(argv, nil)];
    [self setArgs: argv];
}


-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL cmd = [menuItem action];
    if (cmd == @selector(exportShellScript:)) {
        return [_args count] ? YES : NO;
    }
    return [super validateMenuItem: menuItem];
}

# pragma mark - IBActions

- (IBAction)launchAction:(id)sender {

    if (![_args count]) return;

    [LogWindowController controllerForArgs: _args];

}

-(IBAction)exportShellScript: (id)sender {
    
    NSSavePanel *p = [NSSavePanel savePanel];
    
    NSString *defaultName = [_mameMachine stringByAppendingString: @".sh"];
    
    [p setTitle: @"Export Shell Script"];
    [p setExtensionHidden: NO];
    [p setNameFieldStringValue: defaultName];
    
    //[p setDelegate: self];
    
    NSWindow *w = [self window];
    
    NSMutableString *data = [NSMutableString new];
    
    [data appendString: @"#!/bin/sh\n\n"];
    [data appendFormat: @"MAME=%@\n", ShellQuote(MamePath())];
    [data appendFormat: @"cd %@\n", ShellQuote(MameWorkingDirectoryPath())];
    [data appendString: JoinArguments(_args, @"$MAME")];
    [data appendString: @"\n\n"];
    
    [p beginSheetModalForWindow: w completionHandler: ^(NSModalResponse r) {
        
        if (r != NSModalResponseOK) return;
        
        NSURL *url = [p URL];
        NSError *error = nil;
        [data writeToURL: url atomically: YES encoding: NSUTF8StringEncoding error: &error];

        [p orderOut: nil];
        
        if (error) {
            [self presentError: error];
            return;
        }
        
        // chmod 755...
        int ok = chmod([url fileSystemRepresentation], 0755);
        if (ok < 0) {
            // ...
        }
    }];
}

@end


@implementation LaunchWindowController (SoftwareList)

-(void)updateSoftwareList {
    
    _softwareSet = [SoftwareSet softwareSetForMachine: _mameMachine];
    
    [_softwareListControl setAutocompleteDelegate: _softwareSet];
    
    if (_softwareSet) {
        [_softwareListControl invalidate];
        [_softwareListControl setHidden: NO];
    } else {
        _software = nil;
        [_softwareListControl setHidden: YES];
    }
}


- (IBAction)softwareChanged:(id)sender {

    id o = [(NSControl *)sender objectValue];
    //NSLog(@"%@", o);
    [self setSoftware: o];
}

@end
