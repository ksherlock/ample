//
//  SlotViewController.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/18/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "SlotViewController.h"

@interface SlotViewController () {

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


@end

@implementation SlotViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    [self setModel: @"apple2gs"];
}

-(void)reset {
    
}


-(void)setModel:(NSString *)model {
    
    if (model == _model) return;
    if ([model isEqualToString: _model]) return;
    
    _model = model;

    [self loadMachine: model];
}

-(void)resetMachine {

    [self setMachine: @{}];

    [self setSl0: @""];
    [self setSl1: @""];
    [self setSl2: @""];
    [self setSl3: @""];
    [self setSl4: @""];
    [self setSl5: @""];
    [self setSl6: @""];
    [self setSl7: @""];

    [self setRs232: @""];
    [self setAux: @""];
    [self setExp: @""];
    [self setGameio: @""];
    [self setPrinter: @""];
    [self setModem: @""];

    [self setMemory: @""];
    [self setMemoryBytes: 0];
    [self setResolution: NSMakeSize(0, 0)];

    
    [self setArgs: @[]];
}

-(void)loadMachine: (NSString *)model {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: model withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];

    if (!d) {
        [self resetMachine];
        return;
    }


    // n.b. - does content binding propogate immediately?
    [self setMachine: d];
}


- (IBAction)menuChanged:(NSPopUpButton *)sender {

    static NSString *Names[] = {

        @"sl0", @"sl1", @"sl2", @"sl3",
        @"sl4", @"sl5", @"sl6", @"sl7",
        @"exp", @"aux",
        @"gameio", @"printer", @"modem", @"rs232"
    };
    
    NSInteger tag = [sender tag];

//    NSInteger ix = [sender indexOfSelectedItem];
    
    NSString *key = Names[tag];

    NSDictionary *o = [[sender selectedItem] representedObject];
    
    [self setValue: [o objectForKey: @"value"] forKey: key];

    [self rebuildArgs];
}

- (IBAction)memoryMenuChanged:(NSPopUpButton *)sender {

    //
    NSDictionary *o = [[sender selectedItem] representedObject];
    [self setMemory: [o objectForKey: @"description"]];
    [self setMemoryBytes: [(NSNumber *)[o objectForKey: @"value"] unsignedIntValue]];
    
    [self rebuildArgs];
}

-(void)rebuildArgs {
    
    NSMutableArray *args = [NSMutableArray new];
    
#define _(a, b) if ([a length]) { [args addObject: b]; [args addObject: a]; }

    _(_memory, @"-ramsize")

    _(_sl0, @"-sl0")
    _(_sl1, @"-sl1")
    _(_sl2, @"-sl2")
    _(_sl3, @"-sl3")
    _(_sl4, @"-sl4")
    _(_sl5, @"-sl5")
    _(_sl6, @"-sl6")
    _(_sl7, @"-sl7")

    _(_rs232, @"-rs232")
    _(_aux, @"-aux")
    _(_exp, @"-exp")
    _(_gameio, @"-gameio")
    _(_printer, @"-printer")
    _(_modem, @"-modem")


    [self setArgs: args];
}

@end
