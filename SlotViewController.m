//
//  SlotViewController.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/18/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "SlotViewController.h"

const unsigned kMemoryMask = 1 << 16;

@interface SlotViewController () {

    unsigned _slots_explicit;
    unsigned _slots_valid;
    unsigned _slots_default;
    
    NSDictionary *_slot_object[14];
    NSDictionary *_slot_media[14];
    NSDictionary *_machine_media;
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

    _slots_default = 0;
    _slots_explicit = 0;
    _slots_valid = 0;

    _machine_media = nil;
    
    [self setArgs: @[]];
    [self setMedia: @{}];
    

#if 0
    // retain for later?
    for (unsigned i = 0; i < 14; ++i) {
        _slot_media[i] = nil;
        _slot_object[i] = nil;
    }
#endif
}

static NSFont *ItalicMenuFont(void) {
    NSFont *font = [NSFont menuFontOfSize: 0];
    NSFontDescriptor *fd = [font fontDescriptor];
    NSFontDescriptor *fd2 = [fd fontDescriptorWithSymbolicTraits: NSFontDescriptorTraitItalic];
    return [NSFont fontWithDescriptor: fd2 size: [font pointSize]];
}

// entry 0 is None/Empty for slots, but populated for RAM.
static int SetDefaultMenu(NSArray *items, NSPopUpButton *button) {

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
        return ix;
    }
    return 0;
}

static void DeactivateMenus(NSArray *items, NSPopUpButton *button) {
    
    [button setAutoenablesItems: NO];
    unsigned ix = 0;
    for (NSDictionary *d in items) {
        BOOL value = [(NSNumber *)[d objectForKey: @"disabled"] boolValue];
        if (value) {
            
            NSMenuItem *item = [button itemAtIndex: ix];
            [item setEnabled: NO];
        }
        ++ix;
    }
    
}

-(void)syncMemory {
    
    int ix = 0;
    NSArray *items = [_machine objectForKey: @"ram"];

    unsigned default_index = SetDefaultMenu(items, _ram_menu);
    _slots_valid |= kMemoryMask;
    _slots_default &= ~kMemoryMask;
    if (default_index) _slots_default |= kMemoryMask;
    
    if (_slots_explicit & kMemoryMask) {
        // if ram was explicitly set, try to keep it.

        for (NSDictionary *d in items) {
            unsigned size = [(NSNumber *)[d objectForKey: @"value"] unsignedIntValue];
            if (size == _memoryBytes) {
                [_ram_menu selectItemAtIndex: ix];
                [self setMemory: [d objectForKey: @"description"]];
                return;
            }
            ++ix;
        }
    }
    
    _slots_explicit &= ~kMemoryMask;
    if (default_index) {
        NSDictionary *d = [items objectAtIndex: default_index];

        [_ram_menu selectItemAtIndex: default_index];
        [self setMemory: [d objectForKey: @"description"]];
        [self setMemoryBytes: [(NSNumber *)[d objectForKey: @"value"] unsignedIntValue]];
    } else {
        [self setMemoryBytes: 0];
        [self setMemory: @""];
        [_ram_menu selectItemAtIndex: 0];
    }
}

-(void)syncSlot: (NSString *)slot button: (NSPopUpButton *)button index: (unsigned)index {
    
    NSString *value = [self valueForKey: slot];
    NSArray *items = [_machine objectForKey: slot];

    unsigned mask = 1 << index;

    _slots_default &= ~mask;
    _slots_valid &= ~mask;

    if (![items count]) {
        //[self setValue: @"" forKey: slot]; // retain for later.
        //_slots_explicit &= ~mask;
        
        return;
    }
    _slots_valid |= mask;

    DeactivateMenus(items, button);
    unsigned default_index = SetDefaultMenu(items, button);

    if (default_index) _slots_default |= mask;


    if (_slots_explicit & mask) {
        int ix = 0;
        for (NSDictionary *d in items) {
            if ([value isEqualToString: [d objectForKey: @"value"]]) {

                [button selectItemAtIndex: ix];
                _slot_object[index] = d;
                _slot_media[index] = [d objectForKey: @"media"];
                return;
            }
            ++ix;
        }
    }
    _slots_explicit &= ~mask;
    
    if (default_index) {
        NSDictionary *d = [items objectAtIndex: default_index];
        [button selectItemAtIndex: default_index];
        [self setValue: [d objectForKey: @"value"] forKey: slot];
        _slot_object[index] = d;
        _slot_media[index] = [d objectForKey: @"media"];
    } else {
        [button selectItemAtIndex: 0];
        [self setValue: @"" forKey: slot];
        _slot_object[index] = nil;
        _slot_media[index] = nil;
    }
}

-(void)syncSlots {
    
    [self syncMemory];
    [self syncSlot: @"sl0" button: _sl0_menu index: 0];
    [self syncSlot: @"sl1" button: _sl1_menu index: 1];
    [self syncSlot: @"sl2" button: _sl2_menu index: 2];
    [self syncSlot: @"sl3" button: _sl3_menu index: 3];
    [self syncSlot: @"sl4" button: _sl4_menu index: 4];
    [self syncSlot: @"sl5" button: _sl5_menu index: 5];
    [self syncSlot: @"sl6" button: _sl6_menu index: 6];
    [self syncSlot: @"sl7" button: _sl7_menu index: 7];
    [self syncSlot: @"exp" button: _exp_menu index: 8];
    [self syncSlot: @"aux" button: _aux_menu index: 9];
    [self syncSlot: @"rs232" button: _rs232_menu index: 10];
    [self syncSlot: @"gameio" button: _game_menu index: 11];
    [self syncSlot: @"printer" button: _printer_menu index: 12];
    [self syncSlot: @"modem" button: _modem_menu index: 13];
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
    
    _machine_media = [d objectForKey: @"media"];

    // n.b. - does content binding propogate immediately?
    [self setMachine: d];
    [self syncSlots];
    [self rebuildArgs];
    [self rebuildMedia];
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
        
    _slots_explicit |= (1 << tag);

    NSDictionary *o = [[sender selectedItem] representedObject];
    
    [self setValue: [o objectForKey: @"value"] forKey: key];

    _slot_object[tag] = o;
    NSDictionary *newMedia = [o objectForKey: @"media"];
    NSDictionary *oldMedia = _slot_media[tag];

    if (newMedia != oldMedia) {
        _slot_media[tag] = newMedia;
        [self rebuildMedia];
    }
    
    
    [self rebuildArgs];
}

- (IBAction)memoryMenuChanged:(NSPopUpButton *)sender {

    //
    NSDictionary *o = [[sender selectedItem] representedObject];
    NSString *title = [o objectForKey: @"description"];
    [self setMemory: title];
    [self setMemoryBytes: [(NSNumber *)[o objectForKey: @"value"] unsignedIntValue]];
    
    _slots_explicit |= kMemoryMask;

    // if pull-down menu
    if ([sender pullsDown])
        [sender setTitle: title];
    
    [self rebuildArgs];
}

static BOOL should_add_arg(unsigned slot, unsigned valid_slots, unsigned explicit_slots, unsigned default_slots, NSString *value) {
    
    unsigned mask = 1 << slot;
    if (~valid_slots & mask) return NO;

    if (default_slots & mask) {
        if (explicit_slots & mask)
            return YES;
        return NO;
    }
    return [value length];
}

-(void)rebuildArgs {
    
    NSMutableArray *args = [NSMutableArray new];
    
    
    /* if there IS a default card for the slot and nothing is selected, need to -sl0 "" it. */
    

    #define _(ix, a, b) \
    if (should_add_arg(ix, _slots_valid, _slots_explicit, _slots_default, a)) { \
        [args addObject: b]; [args addObject: a]; \
    } \

    _(16, _memory, @"-ramsize")

    _(0, _sl0, @"-sl0")
    _(1, _sl1, @"-sl1")
    _(2, _sl2, @"-sl2")
    _(3, _sl3, @"-sl3")
    _(4, _sl4, @"-sl4")
    _(5, _sl5, @"-sl5")
    _(6, _sl6, @"-sl6")
    _(7, _sl7, @"-sl7")
    _(8, _exp, @"-exp")
    _(9, _aux, @"-aux")
    _(10, _rs232, @"-rs232")
    _(11, _gameio, @"-gameio")
    _(12, _printer, @"-printer")
    _(13, _modem, @"-modem")
#undef _
    [self setArgs: args];
}


-(void)rebuildMedia {
    

#define _(var, o) var += [[o objectForKey: @ # var ] unsignedIntValue]
    
    unsigned cass = 0;
    unsigned cdrm = 0;
    unsigned hard = 0;
    unsigned flop_5_25 = 0;
    unsigned flop_3_5 = 0;

    unsigned mask = 1;
    for (unsigned i = 0; i < 14; ++i, mask <<= 1) {
        
        if (_slots_valid & mask) {
            NSDictionary *tmp = _slot_media[i];
            if (tmp) {
                _(cass, tmp);
                _(cdrm, tmp);
                _(hard, tmp);
                _(flop_5_25, tmp);
                _(flop_3_5, tmp);
            }
        }
    }
    NSDictionary *tmp = _machine_media;
    if (tmp) {
        _(cass, tmp);
        _(cdrm, tmp);
        _(hard, tmp);
        _(flop_5_25, tmp);
        _(flop_3_5, tmp);
    }
    
    [self setMedia: @{
        @"cass": @(cass),
        @"cdrm": @(cdrm),
        @"hard": @(hard),
        @"flop_5_25": @(flop_5_25),
        @"flop_3_5": @(flop_3_5),
    }];
}


@end
