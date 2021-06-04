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
#import "BookmarkManager.h"

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
@property BOOL mameBGFX;

@property BOOL mameAVI;
@property BOOL mameWAV;
@property BOOL mameVGM;

@property NSString *mameAVIPath;
@property NSString *mameWAVPath;
@property NSString *mameVGMPath;
@property NSString *mameShareDirectory;
@property NSString *mameBitBanger;

@property NSInteger mameSpeed;

@property NSInteger mameBackend;
@property NSInteger mameEffects;


@property NSInteger mameWindowMode;

@property (weak) IBOutlet AutocompleteControl *softwareListControl;
@property SoftwareSet *softwareSet;
@property Software *software;



@property (strong) IBOutlet NSWindow *addBookmarkWindow;
@property (strong) NSString *bookmarkName;
@property (weak) IBOutlet NSTextField *bookmarkTextField;
@end

@interface LaunchWindowController (SoftwareList)

-(void)updateSoftwareList;

@end


@interface LaunchWindowController (Bookmark)

-(IBAction)addBookmark:(id)sender;

@end

static NSString *BackendStrings[] = {
    @"",
    @"metal",
    @"opengl",
};

static NSString *EffectsStrings[] = {
    @"-",
    @"unfiltered",
    @"hlsl",
    @"crt-geom",
    @"crt-geom-deluxe",
    @"lcd-grid",
};



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
        @"mameShareDirectory", @"mameBitBanger",
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
            [argv addObject: @"-bgfx_backend"];
            [argv addObject: BackendStrings[_mameBackend]];
        }
        if (_mameEffects) {
            [argv addObject: @"-bgfx_screen_chains"];
            [argv addObject: EffectsStrings[_mameEffects]];
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
    
    if (_mameBitBanger && [_mameBitBanger length]) {
        [argv addObject: @"-bitbanger"];
        [argv addObject: _mameBitBanger];
    }
    
    [self setCommandLine: JoinArguments(argv, nil)];
    [self setArgs: argv];
}


-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL cmd = [menuItem action];
    if (cmd == @selector(exportShellScript:)) {
        return [_args count] ? YES : NO;
    }
    if (cmd == @selector(addBookmark:)) {
        return _mameMachine ? YES : NO;
    }
    
    return YES;
    //return [super validateMenuItem: menuItem]; // not implemented?
}

# pragma mark - IBActions

- (IBAction)launchAction:(id)sender {

    [[self window] makeFirstResponder: nil]; // in case text is being edited...
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


@implementation LaunchWindowController (Bookmark)

-(IBAction)addBookmark:(id)sender {
    
    if (!_mameMachine) return;
    
    NSString *name = _mameMachine;
    if (_software) {
        name = [name stringByAppendingFormat: @" - %@", [_software title]];
    }
    [self setBookmarkName: name];
    [_bookmarkTextField selectText: nil];
    [[self window] beginSheet: _addBookmarkWindow completionHandler:  nil];
}

-(IBAction)bookmarkCancel:(id)sender {
    [[self window] endSheet: _addBookmarkWindow];
    [_addBookmarkWindow orderOut: nil];
}

-(IBAction)bookmarkSave:(id)sender {
    
    
    BookmarkManager *bm = [BookmarkManager sharedManager];

    if (![bm validateName: _bookmarkName]) {
        [_bookmarkTextField selectText: nil];
        NSBeep();
        return;
    }

    
    //NSLog(@"%@", _bookmarkName);
    NSDictionary *d = [self makeBookmark];
    //NSLog(@"%@", d);
    
    [bm saveBookmark: d name: _bookmarkName];
    
    [[self window] endSheet: _addBookmarkWindow];
    [_addBookmarkWindow orderOut: nil];
    [self setBookmarkName: nil];
}


-(IBAction)loadBookmark:(id)sender {
    NSURL *url = [sender representedObject];
    if (!url) return;
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    if (!d) return; // oops...
    
    NSString *machine = [d objectForKey: @"machine"];
    if (!machine) return;

#if 0
    _bookmark = YES;
    [_machineViewController willLoadBookmark];
    [_slotController willLoadBookmark];
    [_mediaController willLoadBookmark];

    
    [self setMameMachine: machine];
    
    [_machineViewController loadBookmark: d];
    [_slotController loadBookmark: d];
    [_mediaController loadBookmark: d];
    
    _bookmark = NO;
    [_machineViewController didLoadBookmark];
    [_slotController didLoadBookmark];
    [_mediaController didLoadBookmark];
    
#endif
    [self buildCommandLine];
}

-(NSDictionary *)makeBookmark {
    
    [[self window] makeFirstResponder: nil];

    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict setObject: _mameMachine forKey: @"machine"];
    [dict setObject: @232 forKey: @"version"];
    [_machineViewController saveBookmark: dict];
    [_slotController saveBookmark: dict];
    [_mediaController saveBookmark: dict];

    
    // Boolean values
#undef _
#define _(v,k) [dict setObject: v ? (NSObject *)kCFBooleanTrue : (NSObject *)kCFBooleanFalse forKey: k]

    _(_mameDebug, @"debug");
    _(_mameSquarePixels, @"squarePixels");
    _(_mameMouse, @"mouse");
    _(_mameSamples, @"samples");
    _(_mameBGFX, @"bgfx");

    // numeric values
    #undef _
    #define _(v,k) [dict setObject: @(v) forKey: k]
    _(_mameWindowMode, @"windowMode");
    _(_mameSpeed, @"speed");

    // String values
#undef _
#define _(v,k) [dict setObject: v forKey: k]

    if (_mameAVI && [_mameAVIPath length]) _(_mameAVIPath, @"AVIPath");
    if (_mameWAV && [_mameWAVPath length]) _(_mameWAVPath, @"WAVPath");
    if (_mameVGM && [_mameVGMPath length]) _(_mameVGMPath, @"VGMPath");

    if ([_mameShareDirectory length]) _(_mameShareDirectory, @"shareDirectory");
    if ([_mameBitBanger length]) _(_mameBitBanger, @"shareDirectory");

    
    if (_software) _([_software fullName], @"software");

    
    if (_mameBackend) _(BackendStrings[_mameBackend], @"backend");
    if (_mameEffects) _(EffectsStrings[_mameEffects], @"effects");

    
    return dict;

#undef _
}


@end
