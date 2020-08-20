//
//  AppDelegate.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "AppDelegate.h"
#import "SlotBrowserDelegate.h"
#import "SlotViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) IBOutlet SlotBrowserDelegate *slotDelegate;
@property (strong) IBOutlet SlotViewController *slotController;


@property (weak) IBOutlet NSView *modelView;
@property (weak) IBOutlet NSView *slotView;

/* kvo */
@property NSString *commandLine;

@property NSString *mameROM;
@property BOOL mameWindow;
@property BOOL mameNoThrottle;
@property BOOL mameDebug;
@property BOOL mameSquarePixels;

@property NSArray *browserItems;
@end

@implementation AppDelegate

static NSString *kMyContext = @"kMyContext";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    
    /* My Copy of XCode/Interface Builder barfs on NSBrowser. */
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource: @"Models" ofType: @"plist"];
    _browserItems = [NSArray arrayWithContentsOfFile: path];
    
    NSView *view = [_window contentView];
    
    NSRect frame;
    NSBrowser *browser = nil;

    frame = [_modelView frame];
    browser = [[NSBrowser alloc] initWithFrame: frame];
    
    [browser setMaxVisibleColumns: 2];
    [browser setTakesTitleFromPreviousColumn: YES];
    [browser setTitled: NO];
    [browser setAllowsEmptySelection: NO];
    [browser setDelegate: self];
    [browser setAction: @selector(modelClick:)];
        
    [view addSubview: browser];
    [browser setTitled: YES]; // NSBrowser title bug.
    
#if 0
    frame = [_slotView frame];
    browser = [[NSBrowser alloc] initWithFrame: frame];
    
    [browser setMaxVisibleColumns: 2];
    [browser setTakesTitleFromPreviousColumn: YES];
    [browser setTitled: NO];
    [browser setDelegate: _slotDelegate];
    //[browser setAction: @selector(modelClick:)];
        
    [view addSubview: browser];
    [browser setTitled: YES]; // NSBrowser title bug.
    [_slotDelegate setBrowser: browser];
#endif
    
    [_slotView addSubview: [_slotController view]];
    
    
    [self addObserver: self forKeyPath: @"mameROM" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameWindow" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameSquarePixels" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameDebug" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self addObserver: self forKeyPath: @"mameNoThrottle" options:0  context: (__bridge void * _Nullable)(kMyContext)];
    [self buildCommandLine];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if (context == (__bridge void *)kMyContext && object == self) {
        [self buildCommandLine];
    } else {
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}

-(void)buildCommandLine {


    if (!_mameROM) {
        [self setCommandLine: @""];
        return;
    }

    NSMutableArray *argv = [NSMutableArray new];

    [argv addObject: @"mame"];
    [argv addObject: _mameROM];
    
    if (_mameDebug) [argv addObject: @"-debug"];
    if (_mameWindow) [argv addObject: @"-window"];
    
    // -nounevenstretch -video soft
    if (_mameWindow && _mameSquarePixels) {

        [argv addObject: @"-nomax"];
        if ([_mameROM hasPrefix: @"apple2gs"]) {
            [argv addObject: @"-resolution"];
            [argv addObject: @"704x462"];
            [argv addObject: @"-video"];
            [argv addObject: @"soft"];
            [argv addObject: @"-aspect"];
            [argv addObject: @"704:462"];
        } else {
            [argv addObject: @"-resolution"];
            [argv addObject: @"560x384"];
            
        }
    }

    if (_mameNoThrottle) [argv addObject: @"-nothrottle"];
    
    [self setCommandLine: [argv componentsJoinedByString:@" "]];
}

-(IBAction)modelClick:(id)sender {
    
    NSDictionary *item = [self itemForBrowser: sender];
    NSString *model = [item objectForKey: @"Mame"];

    [self setMameROM: model];

//    [self buildCommandLine];
    
    [_slotDelegate setModel: model];
    [_slotController setModel: model];
}

#pragma mark NSBrowser

-(NSDictionary *)itemForBrowser: (NSBrowser *)browser {
    
    NSIndexPath *path = [browser selectionIndexPath];
    
    NSArray *a = _browserItems;
    NSDictionary *item = nil;
    
    NSUInteger l = [path length];
    for (NSUInteger i = 0; i < l; ++i) {
        NSUInteger ix = [path indexAtPosition: i];
        if (ix > [a count]) return nil;
        item = [a objectAtIndex: ix];
        a = [item objectForKey: @"Children"];
    }
    
    return item;
}
-(NSArray *)itemsForBrowser: (NSBrowser *)browser column: (NSInteger) column {

    NSArray *a = _browserItems;
    for (unsigned i = 0; i < column; ++i) {
        NSInteger ix = [browser selectedRowInColumn: i];
        if (ix < 0) return 0;

        NSDictionary *item = [a objectAtIndex: ix];
        a = [item objectForKey: @"Children"];
        if (!a) return 0;
    }
    return a;
    
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column {
    NSArray *a = [self itemsForBrowser: sender column: column];
    if (!a || row >= [a count]) return;

    NSDictionary *item = [a objectAtIndex: row];
    
    NSBrowserCell *bc = (NSBrowserCell *)cell;
    
    [bc setStringValue: [item objectForKey: @"Name"]];
    [bc setLeaf: ![item objectForKey: @"Children"]];
    
}


- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(NSInteger)column {
    return column == 0 ? @"Model" : @"Submodel";
}

#if 0
- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    return nil;
}
-(id)rootItemForBrowser:(NSBrowser *)browser {
    return _browserItems;
}
#endif

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column {
    
    NSArray *a = [self itemsForBrowser: sender column: column];
    return [a count];
}



@end
