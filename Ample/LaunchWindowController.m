//
//  LaunchWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "LaunchWindowController.h"
#import "MediaViewController.h"
#import "SlotViewController.h"
#import "MachineViewController.h"
#import "LogWindowController.h"

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
@property BOOL mameWindow;
@property BOOL mameNoThrottle;
@property BOOL mameDebug;
@property BOOL mameSquarePixels;
@property BOOL mameNoBlur;



@end


@implementation LaunchWindowController

-(NSString *)windowNibName {
    return @"LaunchWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.


    [_slotView addSubview: [_slotController view]];
    [_mediaView addSubview: [_mediaController view]];
    [_machineView addSubview: [_machineViewController view]];
    
    
    [self addObserver: self forKeyPath: @"mameMachine" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameWindow" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameSquarePixels" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameDebug" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameNoThrottle" options:0  context: (__bridge void * _Nullable)(kMyContext)];

        [self addObserver: self forKeyPath: @"mameNoBlur" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    
    [_slotController addObserver: self forKeyPath: @"args" options: 0 context: (__bridge void * _Nullable)(kMyContext)];
    [_mediaController addObserver: self forKeyPath: @"args" options: 0 context: (__bridge void * _Nullable)(kMyContext)];

    [_mediaController bind: @"media" toObject: _slotController withKeyPath: @"media" options: 0];
    
    [self buildCommandLine];

    [_machineViewController addObserver: self forKeyPath: @"machine" options: 0 context: (__bridge void * _Nullable)kContextMachine];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if (context == (__bridge void *)kMyContext) {
        [self buildCommandLine];
    } else if (context == (__bridge void *)kContextMachine) {
        NSString *machine = [_machineViewController machine];
        [self setMameMachine: machine];
        [_slotController setModel: machine];
        [self buildCommandLine];
    } else {
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}


static NSURL *MameURL(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];
        
    if ([defaults boolForKey: @"UseSystemMame"]) {
        NSString *path = [defaults stringForKey: @"MamePath"];
        if (![path length]) return [NSURL fileURLWithPath: path];
    }
    
    return [bundle URLForAuxiliaryExecutable: @"mame64"];

    return nil;
}

static NSString *MamePath(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];

    NSString *path;
    
    if ([defaults boolForKey: @"UseCustomMame"]) {
        path = [defaults stringForKey: @"MamePath"];
        if ([path length]) return path;
    }
    path = [bundle pathForAuxiliaryExecutable: @"mame64"];
    if ([path length]) return path;
    return nil;
}


static NSString * JoinArguments(NSArray *argv) {

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
    NSString *path = MamePath();
    path = path ? [path lastPathComponent] : @"mame";
    [rv appendString: path];
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

-(void)buildCommandLine {


    if (!_mameMachine) {
        [self setCommandLine: @""];
        return;
    }

    NSMutableArray *argv = [NSMutableArray new];

    //[argv addObject: @"mame"];
    [argv addObject: _mameMachine];
    
    if (_mameDebug) [argv addObject: @"-debug"];
    if (_mameWindow) {
        [argv addObject: @"-window"];
        [argv addObject: @"-nomax"];
    }

    [argv addObject: @"-skip_gameinfo"];

    if (_mameWindow && _mameSquarePixels) {
        NSSize screen = [_slotController resolution];
        
        NSString *res = [NSString stringWithFormat: @"%ux%u", (unsigned)screen.width, (unsigned)screen.height];
        NSString *aspect = [NSString stringWithFormat: @"%u:%u", (unsigned)screen.width, (unsigned)screen.height];
        
        [argv addObject: @"-nounevenstretch"];

        [argv addObject: @"-resolution"];
        [argv addObject: res];

        [argv addObject: @"-aspect"];
        [argv addObject: aspect];
        
        if (_mameNoBlur) {
            [argv addObject: @"-video"];
            [argv addObject: @"soft"];
        }
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

    if (_mameNoThrottle) [argv addObject: @"-nothrottle"];
    
    
    [self setCommandLine: JoinArguments(argv)]; //[argv componentsJoinedByString:@" "]];
    [self setArgs: argv];
}

# pragma mark - IBActions




- (IBAction)launchAction:(id)sender {

    if (![_args count]) return;
        
    NSURL *url = MameURL();
    
    if (!url) {
        NSAlert *alert = [NSAlert new];

        [alert setMessageText: @"Unable to find MAME executable path"];
        [alert runModal];
        return;
    }
    
    NSTask *task = [NSTask new];
    [task setExecutableURL: url];
    [task setArguments: _args];
#if 0
    // interferes w/ termination notification.
    [task setTerminationHandler: ^(NSTask *t){
        
    }];
#endif
    [LogWindowController controllerForTask: task];
}


@end
