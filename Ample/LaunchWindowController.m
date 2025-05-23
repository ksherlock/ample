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
#import "NewMachineViewController.h"
#import "LogWindowController.h"

#import "AutocompleteControl.h"
#import "SoftwareList.h"
#import "BookmarkManager.h"
#import "Bookmark.h"

#include <sys/stat.h>
#include <wctype.h>

static NSString *kMyContext = @"kMyContext";
static NSString *kContextMachine = @"kContextMachine";


static NSString *NeedsAspectRatio(NSString *machine) {
    static NSDictionary *dict = nil;
    
    /* these are all non-60hz? */
    if (!dict) {
        dict = @{
            @"c64": @"3:2",
            @"c64c": @"3:2",
            @"oric1": @"2:1",
            @"orica": @"2:1",
            @"prav8d": @"2:1",
            @"telstrat": @"2:1",
        };
    }
    return [dict objectForKey: machine];
}

static BOOL NeedsNatural(NSString *machine) {

    static NSSet *set = nil;
    
    /* these all have really strange keyboards */
    if (!set) {
        NSArray *machines = @[
            @"bbcb", @"bbca", @"bbcb_de", @"bbcb_us", @"bbcb_no", @"bbcbp", @"bbcbp128", @"bbcm", @"bbcmt", @"bbcmc", @"electron",
            @"c64", @"c64c", @"c128"
        ];
        set = [NSSet setWithArray: machines];
    }
    return [set containsObject: machine];
}

static BOOL HasLayout(NSString *machine) {

    static NSSet *set = nil;
    
    /* these have a layout which adds 10% to the height. */
    if (!set) {
        NSArray *machines = @[
            @"bbcb", @"bbca", @"bbcb_de", @"bbcb_us", @"bbcb_no", @"bbcbp", @"bbcbp128", @"bbcm", @"bbcmt", @"bbcmc", @"electron",
            @"vt100", @"vt101", @"vt102", @"vt105", @"vt131", @"vt180"
        ];
        set = [NSSet setWithArray: machines];
    }
    return [set containsObject: machine];
}

@interface LaunchWindowController () {
    BOOL _loadingBookmark;
    NSString *_machine;
    NSDictionary *_machineDescription;
    BookmarkManager *_manager;
}
@property (strong) IBOutlet MediaViewController *mediaController;
@property (strong) IBOutlet SlotViewController *slotController;
@property (strong) IBOutlet NewMachineViewController *machineViewController;

@property (weak) IBOutlet NSView *machineView;
@property (weak) IBOutlet NSView *slotView;
@property (weak) IBOutlet NSView *mediaView;

/* kvo */
@property NSString *commandLine;
@property NSArray *args;

@property NSString *machine;
//@property NSString *machineName;

@property BOOL mameDebug;
@property BOOL mameSquarePixels;
@property BOOL mameMouse;
@property BOOL mameSamples;
@property BOOL mameBGFX;
@property BOOL mameRewind;

@property BOOL mameAVI;
@property BOOL mameWAV;
@property BOOL mameVGM;
@property BOOL mameBitBanger;
@property BOOL mameShareDirectory;

@property NSString *mameAVIPath;
@property NSString *mameWAVPath;
@property NSString *mameVGMPath;
@property NSString *mameShareDirectoryPath;
@property NSString *mameBitBangerPath;

@property NSInteger mameSpeed;

@property NSInteger mameBackend;
@property NSInteger mameEffects;


@property NSInteger mameWindowMode;

@property (weak) IBOutlet AutocompleteControl *softwareListControl;
@property SoftwareSet *softwareSet;
@property Software *software;



@property (strong) IBOutlet NSWindow *addBookmarkWindow;
@property (strong) NSString *bookmarkName;
@property BOOL bookmarkDefault;
@property (weak) IBOutlet NSTextField *bookmarkTextField;
@property (weak) IBOutlet NSTextField *bookmarkErrorField;

@property BOOL optionKey;


@end

@interface LaunchWindowController (SoftwareList)

-(void)updateSoftwareList;

@end


@interface LaunchWindowController (Bookmark)

-(IBAction)addBookmark:(id)sender;

-(IBAction)defaultLoad:(id)sender;

-(void)bookmarkNotification: (NSNotification *)notification;

@end

#define SIZEOF(x) (sizeof(x) / sizeof(x[0]))
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
    @"Fighters",
};


static int BackEndIndex(NSString *str) {
    if (!str) return -1;
    for (int i = 1; i < SIZEOF(BackendStrings); ++i) {
        if ([str isEqualToString: BackendStrings[i]]) return i;
    }
    return -1;
}

static int EffectsIndex(NSString *str) {
    if (!str) return -1;
    for (int i = 1; i < SIZEOF(EffectsStrings); ++i) {
        if ([str isEqualToString: EffectsStrings[i]]) return i;
    }
    return -1;
}


@implementation LaunchWindowController

-(NSString *)windowNibName {
    return @"LaunchWindow";
}

-(void)reset {
    // handled elsewhere.
    //[self setMachine: nil];

    [self setMameSpeed: 1];
    [self setMameBGFX: YES];
    [self setMameMouse: NO];
    [self setMameSamples: NO];
    [self setMameSquarePixels: NO];
    [self setMameDebug: NO];
    [self setMameRewind: NO];
    [self setMameWindowMode: 1]; // default = 1x window.

    [self setMameBackend: 0];
    [self setMameEffects: 0];

    [self setMameBitBangerPath: nil];
    [self setMameShareDirectoryPath: nil];
    [self setMameAVIPath: nil];
    [self setMameWAVPath: nil];
    [self setMameVGMPath: nil];

    [self setMameAVI: NO];
    [self setMameWAV: NO];
    [self setMameVGM: NO];
    [self setMameBitBanger: NO];
    [self setMameShareDirectory: NO];

#if 0
    [self setSoftware: nil];
    //_softwareSet = nil;
    [_softwareListControl setObjectValue: nil];
#endif
}

-(void)resetSoftware {
    [self setSoftware: nil];
    //_softwareSet = nil;
    [_softwareListControl setObjectValue: nil];
}

-(void)windowWillLoad {

    _manager = [BookmarkManager sharedManager];
    
    // if this calls [self window], it will recurse.  that is bad.
    //[self defaultLoad: nil];
    [self reset];
}



static void AddSubview(NSView *parent, NSView *child) {
    
    [child setFrame: [parent bounds]];
    [parent addSubview: child];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    

    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    AddSubview(_slotView, [_slotController view]);
    AddSubview(_mediaView, [_mediaController view]);
    AddSubview(_machineView, [_machineViewController view]);

    
    [_softwareListControl setMinWidth: 250];
    [_softwareListControl setHidden: YES];


    NSArray *keys = @[
        //@"mameMachine", // - handled
        @"mameSquarePixels", @"mameWindowMode",
        @"mameMouse", @"mameSamples",
        @"mameDebug", @"mameRewind",
        @"mameSpeed",
        @"mameAVI", @"mameAVIPath",
        @"mameWAV", @"mameWAVPath",
        @"mameVGM", @"mameVGMPath",
        @"mameShareDirectory", @"mameShareDirectoryPath",
        @"mameBitBanger", @"mameBitBangerPath",
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

    
    
    
    // can't be done until above views are set up.
    [self defaultLoad: nil];

    
    [self buildCommandLine];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self selector: @selector(bookmarkNotification:) name: kNotificationBookmarkMagicRoute object: nil];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if (context == (__bridge void *)kMyContext) {
        if (_loadingBookmark) return;
        [self buildCommandLine];
    } else if (context == (__bridge void *)kContextMachine) {
        if (_loadingBookmark) return;

        NSString *machine = [_machineViewController machine];
        [self setMachine: machine];
        [_slotController setMachine: machine];
        [self buildCommandLine];
    } else {
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}



-(NSString *)machine {
    return _machine;
}

-(void)setMachine:(NSString *)machine {
    if (_machine == machine) return;
    _machine = machine;
    _machineDescription = MameMachine(machine);

#if 0
    [self setMachineName: [_machineDescription objectForKey: @"description"]];
#else
    NSString *title = _machineDescription
        ? [NSString stringWithFormat: @"Ample – %@", [_machineDescription objectForKey: @"description"]]
        : @"Ample";

    [[self window] setTitle: title];
#endif
    
    // enable/disable the right-click menu
    NSWindow *window = [self window];
    NSView *view = [window contentView];
    if (_machine) [view setMenu: [window menu]];
    else [view setMenu: nil];
    
    
    // software list.
    [self updateSoftwareList];
}

static NSString * JoinArguments(NSArray *argv, NSString *argv0) {

    static NSCharacterSet *safe = nil;
    static NSCharacterSet *unsafe = nil;

    if (!safe) {
        NSString *str =
            @"%+-./:=_,"
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
            @"%+-./:=_,"
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

    if (!_machine) {
        [self setCommandLine: @""];
        return;
    }

    NSMutableArray *argv = [NSMutableArray new];

    //[argv addObject: @"mame"];
    [argv addObject: _machine];
    
    // -confirm_quit?
    [argv addObject: @"-skip_gameinfo"];

    // natural keyboard on by default.
    if (NeedsNatural(_machine))
        [argv addObject: @"-natural"];
    
    if (_mameMouse)
        [argv addObject: @"-mouse"]; // capture the mouse cursor when over the window.

    if (!_mameSamples)
        [argv addObject: @"-nosamples"];
    
    if (_mameDebug) [argv addObject: @"-debug"];
    if (_mameRewind) [argv addObject: @"-rewind"];

    
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
        case 4: // 4x
            
            if (_mameSquarePixels) {
                //              NSString *aspect = [NSString stringWithFormat: @"%u:%u", (unsigned)screen.width, (unsigned)screen.height];
                //              [argv addObject: @"-aspect"];
                //              [argv addObject: aspect];

                float hscale = round((screen.width * 3 / 4) / screen.height);
                if (hscale < 1) hscale = 1;
                screen.height *= hscale;


            } else {
                screen.height = round(screen.width * 3 / 4);
            }
            
            if (HasLayout(_machine)) {
                screen.height = round(screen.height * 1.1);
            }
            
            [argv addObject: @"-window"];
            NSString *res = [NSString stringWithFormat: @"%ux%u",
                   (unsigned)(_mameWindowMode * screen.width),
                   (unsigned)(_mameWindowMode * screen.height)
                   ];

            [argv addObject: @"-resolution"];
            [argv addObject: res];
            if (_mameSquarePixels) {
                [argv addObject: @"-nounevenstretch"];

                NSString *aspect = NeedsAspectRatio(_machine);
                if (aspect) {
                    [argv addObject: @"-aspect"];
                    [argv addObject: aspect];
                }

            }
            break;
    }




    if (_mameBGFX) {
        [argv addObject: @"-video"];
        [argv addObject: @"bgfx"];

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

    // software *AFTER* slots so, eg, apple2ee has access to the superdrive.
    if (_software) {
        NSString *name = [_softwareSet nameForSoftware: _software];
        if (name) [argv addObject: name];
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
    
    if (_mameShareDirectory && [_mameShareDirectoryPath length]) {
        [argv addObject: @"-share_directory"];
        [argv addObject: _mameShareDirectoryPath];
    }
    
    if (_mameBitBanger && [_mameBitBangerPath length]) {
        [argv addObject: @"-bitbanger"];
        [argv addObject: _mameBitBangerPath];
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
        return _machine ? YES : NO;
    }
    
    return YES;
    //return [super validateMenuItem: menuItem]; // not implemented?
}

-(void)defocus {
    [[self window] makeFirstResponder: nil]; // in case text is being edited...
}

# pragma mark - IBActions

- (IBAction)launchAction:(id)sender {

    [self defocus];
    if (![_args count]) return;

    [LogWindowController controllerForArgs: _args];

}


- (IBAction)listMedia:(id)sender {

    [self defocus];
    if (!_machine) return;
    
    NSMutableArray *argv = [NSMutableArray new];

    [argv addObject: _machine];
    [argv addObject: @"-listmedia"];

    
    NSArray *tmp;
    tmp = [_slotController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }

#if 0
    tmp = [_mediaController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }
#endif

    [LogWindowController controllerForArgs: argv close: NO];
}

- (IBAction)listSlots:(id)sender {

    [self defocus];
    if (!_machine) return;
    
    NSMutableArray *argv = [NSMutableArray new];

    [argv addObject: _machine];
    [argv addObject: @"-listslots"];

    
    NSArray *tmp;
    tmp = [_slotController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }

#if 0
    tmp = [_mediaController args];
    if ([tmp count]) {
        [argv addObjectsFromArray: tmp];
    }
#endif

    [LogWindowController controllerForArgs: argv close: NO];
}


-(IBAction)exportShellScript: (id)sender {
    
    NSSavePanel *p = [NSSavePanel savePanel];
    
    NSString *defaultName = [_machine stringByAppendingString: @".sh"];
    
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


-(IBAction)resetMachine:(id)sender {
    [self reset];
}

-(IBAction)resetAll:(id)sender {

    [_manager setCurrentBookmark: nil];
    [self reset];
    [self resetSoftware];
    [_slotController resetSlots: sender];
    [_mediaController resetMedia: sender];
}

-(IBAction)resetMedia:(id)sender {
    [_mediaController resetMedia: sender];
    [_softwareListControl setObjectValue: nil];
    [self setSoftware: nil];
}


@end


@implementation LaunchWindowController (SoftwareList)

-(void)updateSoftwareList {
    
    _softwareSet = [SoftwareSet softwareSetForMachine: _machine];
    
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

-(IBAction)defaultSave:(id)sender {

#if 0
    NSDictionary *d = [self makeBookmark];

    [_manager saveDefault: d];
#endif
}

-(IBAction)defaultLoad:(id)sender {

    Bookmark *b = [_manager defaultBookmark];

    if (!b) {
        [self resetAll: sender];
        [self setMachine: nil];
        [_machineViewController reset];
        [_slotController setMachine: nil];
        return;
    }
    [self loadBookmark: b];
}

-(IBAction)updateBookmark: (id)sender {
    
    Bookmark *b = [sender representedObject];
    if (!b) return;
    
    NSDictionary *d = [self makeBookmark];
    [b setDictionary: d];
}

-(IBAction)addBookmark:(id)sender {
    
    if (!_machine) return;

    NSString *name = nil;
    if (_machineDescription) name = [_machineDescription objectForKey:@"description"];
    if (!name) name = _machine;

        
    if (_software) {
        name = [name stringByAppendingFormat: @" - %@", [_software title]];
    }
    
    name = [_manager uniqueBookmarkName: name];
    
    [self setBookmarkName: name];
    [self setBookmarkDefault: NO];
    [_bookmarkTextField selectText: nil];
    [_bookmarkErrorField setStringValue: @""];

    [[self window] beginSheet: _addBookmarkWindow completionHandler:  nil];
}

-(IBAction)bookmarkCancel:(id)sender {
    [[self window] endSheet: _addBookmarkWindow];
    [_addBookmarkWindow orderOut: nil];
}

-(IBAction)bookmarkSave:(id)sender {
        

#if 0
    if (![_manager validateName: _bookmarkName]) {
        [_bookmarkTextField selectText: nil];
        NSBeep();
        return;
    }
#endif

    NSDictionary *d = [self makeBookmark];
    NSError *e;
    
    if (( e = [_manager saveBookmark: d name: _bookmarkName automatic: _bookmarkDefault])) {
        // probably a duplicate name...
        [_bookmarkTextField selectText: nil];
        [_bookmarkErrorField setStringValue: [e localizedDescription]];
        NSBeep();
        return;
    }
    
    [[self window] endSheet: _addBookmarkWindow];
    [_addBookmarkWindow orderOut: nil];
    [self setBookmarkName: nil];
}


-(void)bookmarkNotification: (NSNotification *)notification {
    
    Bookmark *b = [notification object];
    [self loadBookmark: b];
}

-(IBAction)bookmarkMenu:(id)sender {

    // represented object is a Bookmark.
    Bookmark *b = [sender representedObject];
    [self loadBookmark: b];
}


-(void)loadBookmark: (Bookmark *)b {
    Class StringClass = [NSString class];
    Class NumberClass = [NSNumber class];

    NSDictionary *d = [b dictionary];

    [_manager setCurrentBookmark: b];
    
    NSString *machine = [d objectForKey: @"machine"];
    if (!machine) return;

    _loadingBookmark = YES;
    [_machineViewController willLoadBookmark: d];
    [_slotController willLoadBookmark: d];
    [_mediaController willLoadBookmark: d];

    [self reset];
    [self resetSoftware];
    
    [self setMachine: machine];
    [self updateSoftwareList];
    [_softwareListControl setObjectValue: nil]; // will reload the completion list.
    
    NSString *str;

    str = [d objectForKey: @"software"];
    if ([str isKindOfClass: StringClass]) {
        Software *s = [_softwareSet softwareForName: str];
        if (s) {
            [_softwareListControl setObjectValue: s];
            [self setSoftware: s];
        }
        
    }

    // Boolean values.
    NSNumber *n;
#undef _
#define _(a,b) n = [d objectForKey: a]; if ([n isKindOfClass: NumberClass]) [self b : [n boolValue]]
  
    _(@"debug", setMameDebug);
    _(@"rewind", setMameRewind);
    _(@"squarePixels", setMameSquarePixels);
    _(@"mouse", setMameMouse);
    _(@"samples", setMameSamples);
    _(@"bgfx", setMameBGFX);
    
    // numeric values
    // check if in range?
#undef _
    #define _(a,b) n = [d objectForKey: a]; if ([n isKindOfClass: NumberClass]) [self b : [n intValue]]

    _(@"windowMode", setMameWindowMode);
    _(@"speed", setMameSpeed);
    

    // string values
#undef _
    #define _(a,b) str = [d objectForKey: a]; if ([str isKindOfClass: StringClass]) [self b : str]

    _(@"shareDirectory", setMameShareDirectoryPath);
    _(@"bitBanger", setMameBitBangerPath);
    if ([_mameShareDirectoryPath length]) [self setMameShareDirectory: YES];
    if ([_mameBitBangerPath length]) [self setMameBitBanger: YES];

    _(@"AVIPath", setMameAVIPath);
    _(@"WAVPath", setMameWAVPath);
    _(@"VGMPath", setMameVGMPath);
    if ([_mameAVIPath length]) [self setMameAVI: YES];
    if ([_mameVGMPath length]) [self setMameVGM: YES];
    if ([_mameWAVPath length]) [self setMameWAV: YES];


    str = [d objectForKey: @"backend"];
    if ([str isKindOfClass: [NSString class]]) {
        int ix = BackEndIndex(str);
        if (ix >= 0) [self setMameBackend: ix];
    }

    str = [d objectForKey: @"effects"];
    if ([str isKindOfClass: [NSString class]]) {
        int ix = EffectsIndex(str);
        if (ix >= 0) [self setMameEffects: ix];
    }
    
    [_machineViewController loadBookmark: d];
    [_slotController loadBookmark: d];
    [_mediaController loadBookmark: d];
    
    [_machineViewController didLoadBookmark: d];
    [_slotController didLoadBookmark: d];
    [_mediaController didLoadBookmark: d];

    _loadingBookmark = NO;

    [self buildCommandLine];
}

-(NSDictionary *)makeBookmark {
    
    [self defocus];

    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict setObject: _machine forKey: @"machine"];
    [dict setObject: @232 forKey: @"version"];
    [_machineViewController saveBookmark: dict];
    [_slotController saveBookmark: dict];
    [_mediaController saveBookmark: dict];

    
    // Boolean values
#undef _
#define _(v,k) [dict setObject: v ? (NSObject *)kCFBooleanTrue : (NSObject *)kCFBooleanFalse forKey: k]

    _(_mameDebug, @"debug");
    _(_mameRewind, @"rewind");
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

    if (_mameShareDirectory && [_mameShareDirectoryPath length]) _(_mameShareDirectoryPath, @"shareDirectory");
    if (_mameBitBanger && [_mameBitBangerPath length]) _(_mameBitBangerPath, @"bitBanger");

    
    if (_software) _([_software fullName], @"software");

    
    if (_mameBackend) _(BackendStrings[_mameBackend], @"backend");
    if (_mameEffects) _(EffectsStrings[_mameEffects], @"effects");

    
    return dict;

#undef _
}


#pragma mark - NSMenuDelegate

#if 1
-(void)menuNeedsUpdate:(NSMenu *)menu {
    NSEventModifierFlags modifiers = [NSEvent modifierFlags];
    
    [self setOptionKey: modifiers & NSEventModifierFlagOption ? YES : NO];
}

#else
/* doesn't trigger when menu is the first responder. */
-(void)flagsChanged:(NSEvent *)event {
    NSEventModifierFlags modifiers = [event modifierFlags];

    [self setOptionKey: modifiers & NSEventModifierFlagOption ? YES : NO];

    [super flagsChanged: event];
}
#endif

@end
