//
//  SlotViewController.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/18/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "SlotViewController.h"

@interface SlotViewController () {
//NSDictionary *_machine;
}

@property (weak) IBOutlet NSPopUpButton *ram_menu;
@property (weak) IBOutlet NSPopUpButton *sl0_menu;
@property (weak) IBOutlet NSPopUpButton *sl1_menu;
@property (weak) IBOutlet NSPopUpButton *sl2_menu;
@property (weak) IBOutlet NSPopUpButton *sl3_menu;
@property (weak) IBOutlet NSPopUpButton *sl4_menu;
@property (weak) IBOutlet NSPopUpButton *sl5_menu;
@property (weak) IBOutlet NSPopUpButton *sl6_menu;
@property (weak) IBOutlet NSPopUpButton *sl7_menu;
@property (weak) IBOutlet NSPopUpButton *sl8_menu;
@property (weak) IBOutlet NSPopUpButton *exp_menu;
@property (weak) IBOutlet NSPopUpButton *aux_menu;
@property (weak) IBOutlet NSPopUpButton *rs232_menu;
@property (weak) IBOutlet NSPopUpButton *game_menu;
@property (weak) IBOutlet NSPopUpButton *printer_menu;
@property (weak) IBOutlet NSPopUpButton *modem_menu;

@property (strong) IBOutlet NSArrayController *ram_array;

@property NSArray *ram_menu_values;

@property NSDictionary *machine;

@end

@implementation SlotViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self setRam_menu_values: @[]];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: @"apple2gs" withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    [self setMachine: d];

    //[self update_ram_menu];
    
    
    
}

-(void)reset {
    
}
- (IBAction)ram_menu_action:(id)sender {
    NSLog(@"%@", sender);
}

static NSMenuItem *MemoryMenuItem(unsigned size) {

    NSMenuItem *m;
    NSString *s;
    
    if (size >= 1024 * 1024)
        s = [NSString stringWithFormat: @"%fM", (double)size / (1024 * 1024)];
    else
        s = [NSString stringWithFormat: @"%uK", size / 1024];

    m = [[NSMenuItem alloc] initWithTitle: s action: nil keyEquivalent: @""];

    [m setTag: size];
    return m;
}

-(void)update_ram_menu {
#if 0
    NSMenu *menu = [_ram_menu menu];
    
    [menu removeAllItems];
    
    [menu addItem: MemoryMenuItem(4096)];
    [menu addItem: MemoryMenuItem(1310720)];
    [menu addItem: MemoryMenuItem(5242880)];

    [_ram_array setContent: @[
     @{ @"description" : @"4K" },
     @{ @"description" : @"8K" },
     @{ @"description" : @"16K" }
     ]
     ];
    
#endif
    [self setRam_menu_values: [_machine objectForKey: @"RAM"]];
    //[_ram_array setContent: [_machine objectForKey: @"RAM"]];
}

-(void)setModel:(NSString *)model {
    
    if (model == _model) return;
    if ([model isEqualToString: _model]) return;
    
    _model = model;
    _machine = nil;
    
    NSGridView *view = (NSGridView *)[self view];
    if (!_model) {
        [view setHidden: YES];
        [self setMemory: 0];
        return;
    }
    
    /* load ... */
    
    /* ram menu */
    [_ram_menu removeAllItems];
    [self update_ram_menu];
    
}

@end
