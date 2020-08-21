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

static NSFont *ItalicMenuFont(void) {
    NSFont *font = [NSFont menuFontOfSize: 0];
    NSFontDescriptor *fd = [font fontDescriptor];
    NSFontDescriptor *fd2 = [fd fontDescriptorWithSymbolicTraits: NSFontDescriptorTraitItalic];
    return [NSFont fontWithDescriptor: fd2 size: [font pointSize]];
}

static void SetDefaultMenu(NSArray *items, NSPopUpButton *button) {

    static NSDictionary *attr = nil;
    if (!attr) {
        attr = @{
            NSFontAttributeName: ItalicMenuFont()
        };
    }

    unsigned ix = 0;

    
    for (NSDictionary *d in items) {
        BOOL def = [(NSNumber *)[d objectForKey: @"default"] boolValue];
        if (!def) {
            ++ix;
            continue;
        }

        NSMenuItem *item = [button itemAtIndex: ix];
        NSString *title = [d objectForKey: @"description"];
        NSAttributedString *t = [[NSAttributedString alloc] initWithString: title attributes: attr];
        [item setAttributedTitle: t];
        return;
    }
        
}

-(void)syncMemory {
    
    int ix = 0;
    NSArray *items = [_machine objectForKey: @"RAM"];

    SetDefaultMenu(items, _ram_menu);
    
    for (NSDictionary *d in items) {
        unsigned size = [(NSNumber *)[d objectForKey: @"value"] unsignedIntValue];
        if (size == _memoryBytes) {
            [_ram_menu selectItemAtIndex: ix];
            [self setMemory: [d objectForKey: @"description"]];
            return;
        }
        ++ix;
    }

    [self setMemoryBytes: 0];
    [self setMemory: @""];
    [_ram_menu selectItemAtIndex: 0];
    /* set to default */
    
}

-(void)syncSlot: (NSString *)slot button: (NSPopUpButton *)button {
    
    NSString *value = [self valueForKey: slot];
    NSArray *items = [_machine objectForKey: slot];

    SetDefaultMenu(items, button);

    if (![value length]) return;

    
    if (![items count]) {
        [self setValue: @"" forKey: slot];
        return;
    }

    int ix = 0;
    for (NSDictionary *d in items) {
        if ([value isEqualToString: [d objectForKey: @"value"]]) {

            [button selectItemAtIndex: ix];
            return;
        }
        ++ix;
    }
    [self setValue: @"" forKey: slot];
    [button selectItemAtIndex: 0];
}

-(void)syncSlots {
    
    [self syncMemory];
    [self syncSlot: @"sl0" button: _sl0_menu];
    [self syncSlot: @"sl1" button: _sl1_menu];
    [self syncSlot: @"sl2" button: _sl2_menu];
    [self syncSlot: @"sl3" button: _sl3_menu];
    [self syncSlot: @"sl4" button: _sl4_menu];
    [self syncSlot: @"sl5" button: _sl5_menu];
    [self syncSlot: @"sl6" button: _sl6_menu];
    [self syncSlot: @"sl7" button: _sl7_menu];
    [self syncSlot: @"rs232" button: _rs232_menu];
    [self syncSlot: @"aux" button: _aux_menu];
    [self syncSlot: @"exp" button: _exp_menu];
    [self syncSlot: @"gameio" button: _game_menu];
    [self syncSlot: @"modem" button: _modem_menu];
    [self syncSlot: @"printer" button: _printer_menu];
}

-(void)loadMachine: (NSString *)model {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: model withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];

    if (!d) {
        [self resetMachine];
        return;
    }

    NSArray *r = [d objectForKey: @"Resolution"];
    NSSize res = NSMakeSize(0, 0);
    if (r) {
        res.width = [(NSNumber *)[r objectAtIndex: 0 /*@"width"*/] doubleValue];
        res.height = [(NSNumber *)[r objectAtIndex: 1 /*@"height"*/] doubleValue];
    }
    [self setResolution: res];

    // n.b. - does content binding propogate immediately?
    [self setMachine: d];
    [self syncSlots];
    [self rebuildArgs];
}


- (IBAction)menuChanged:(NSPopUpButton *)sender {

    static NSString *Names[] = {

        @"sl0", @"sl1", @"sl2", @"sl3",
        @"sl4", @"sl5", @"sl6", @"sl7",
        @"exp", @"aux", @"rs232",
        @"gameio", @"printer", @"modem",
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
    NSString *title = [o objectForKey: @"description"];
    [self setMemory: title];
    [self setMemoryBytes: [(NSNumber *)[o objectForKey: @"value"] unsignedIntValue]];
    
    // if pull-down menu
    if ([sender pullsDown])
        [sender setTitle: title];
    
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
