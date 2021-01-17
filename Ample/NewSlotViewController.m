//
//  NewSlotViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/9/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "NewSlotViewController.h"
#import "Menu.h"

/* number of slot types.  bitmask used so should be < sizeof(unsigned *8) */
#define MAX_SLOTS 24
static_assert(MAX_SLOTS <= sizeof(unsigned) * 8, "too many slot types");

#define SIZEOF(x) (sizeof(x) / sizeof(x[0]))

@implementation SlotTableCellView

@end

@implementation SlotItem

-(id)init {
    _defaultIndex = -1;
    _selectedIndex = -1;

    return self;
}

-(NSString *)label {
    static NSString *Names[] = {
        @"RAM:",
        @"Slot 0:",
        @"Slot 1:",
        @"Slot 2:",
        @"Slot 3:",
        @"Slot 4:",
        @"Slot 5:",
        @"Slot 6:",
        @"Slot 7:",
        @"Expansion:",
        @"Auxiliary:",
        @"RS232:",
        @"Game I/O:",
        @"Modem:",
        @"Printer:",

        // nubus mac
        @"Slot 9:",
        @"Slot A:",
        @"Slot B:",
        @"Slot C:",
        @"Slot D:",
        @"Slot E:",
    };

    static_assert(SIZEOF(Names) <= MAX_SLOTS, "label overflow");
    return Names[_index];
}

-(NSString *)flag {

    static NSString *Names[] = {
        @"-ramsize",
        @"-sl0",
        @"-sl1",
        @"-sl2",
        @"-sl3",
        @"-sl4",
        @"-sl5",
        @"-sl6",
        @"-sl7",
        @"-exp",
        @"-aux",
        @"-rs232",
        @"-gameio",
        @"-modem",
        @"-printer",
        
        // nubus mac
        @"-nb9",
        @"-nba",
        @"-nbb",
        @"-nbc",
        @"-nbd",
        @"-nbe",
    };
    static_assert(SIZEOF(Names) <= MAX_SLOTS, "flag overflow");
    return Names[_index];
    
}

-(void)buildMenuWithSelectedValue: (NSString *)value {
    
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity: [_children count]];
    _defaultIndex = -1;
    _selectedIndex = -1;
    
    int ix = 0;
    for (NSDictionary *d in _children) {
        NSString *title = [d objectForKey: @"description"];
        NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle: title  action: NULL keyEquivalent: @""];
        
        // row 0 for slots is -- None -- which should be nil...
        [mi setRepresentedObject: d];

        
        BOOL disabled = [(NSNumber *)[d objectForKey: @"disabled"] boolValue];
        if (disabled) {
            [mi setEnabled: NO];
        }
        
        BOOL def = [(NSNumber *)[d objectForKey: @"default"] boolValue];
        if (def) {
            [mi setAttributedTitle: ItalicMenuString(title)];
            _defaultIndex = ix;
        }
        
        if (value) {
            NSString *v = [d objectForKey: @"value"];
            if ([value compare: v] == NSOrderedSame) {
                _selectedIndex = ix;
            }
        }
        
        [tmp addObject: mi];
        ++ix;
    }
    
    
    [self setMenuItems: tmp];
    if (_selectedIndex < 0) _selectedIndex = _defaultIndex;
    if (_selectedIndex < 0) _selectedIndex = 0;
}

-(void)reset {
    [self setSelectedIndex: _defaultIndex >= 0 ? _defaultIndex : 0];
}

-(NSDictionary *)selectedItem {
    if (_selectedIndex < 0) return nil;
    return [_children objectAtIndex: _selectedIndex];
}

-(NSDictionary *)selectedMedia {
    if (_selectedIndex < 0) return nil;
    NSDictionary *d = [_children objectAtIndex: _selectedIndex];
    return [d objectForKey: @"media"];
}

-(BOOL)hasDefault {
    return _defaultIndex >= 0;
}

-(void)prepareView: (SlotTableCellView *)view {
    
    NSPopUpButton *button = [view menuButton];
    NSTextField *text = [view textField];
    
    [text setObjectValue: [self label]];
    
    [button unbind: @"selectedIndex"];
    [[button menu] setItemArray: _menuItems];
    [button bind: @"selectedIndex" toObject: self withKeyPath: @"selectedIndex" options: nil];
    [button setTag: _index];
}

@end





@interface NewSlotViewController ()
@property (weak) IBOutlet NSOutlineView *outlineView;

@end

@implementation NewSlotViewController {
    NSMutableArray *_root;

    unsigned _slots_explicit;
    unsigned _slots_valid;
    unsigned _slots_default;

    NSDictionary *_slot_object[MAX_SLOTS];
    NSDictionary *_slot_media[MAX_SLOTS];
    NSString *_slot_value[MAX_SLOTS]; // when explicitely set.
    NSDictionary *_machine_media;
    
    NSDictionary *_machine_data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    _root = [NSMutableArray new];
}

-(void)resetMachine {

    [_root removeAllObjects];
    [_outlineView reloadData];

    _slots_valid = 0;
    _slots_explicit = 0;
    _slots_default = 0;
    _machine_media = nil;
    _machine_data = nil;
    
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {
        _slot_media[i] = nil;
        _slot_object[i] = nil;
        _slot_value[i] = nil;
    }

    [self setResolution: NSMakeSize(0, 0)];
    [self setArgs: @[]];
    [self setMedia: @{}];
}

-(void)loadMachine {

    static NSString *Keys[] = {
        @"ram",
        @"sl0", @"sl1", @"sl2", @"sl3",
        @"sl4", @"sl5", @"sl6", @"sl7",
        @"exp", @"aux", @"rs232",
        @"gameio", @"printer", @"modem",
        
        // mac
        @"nb9", @"nba", @"nbb", @"nbc", @"nbd", @"nbe",
    };
    
    static_assert(SIZEOF(Keys) <= MAX_SLOTS, "key overflow");
    static unsigned SizeofKeys = SIZEOF(Keys);
    
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: _machine withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];

    if (!d) {
        [self resetMachine];
        return;
    }

    NSArray *r = [d objectForKey: @"resolution"];
    NSSize res = NSMakeSize(0, 0);
    if (r) {
        res.width = [(NSNumber *)[r objectAtIndex: 0 /*@"width"*/] doubleValue];
        res.height = [(NSNumber *)[r objectAtIndex: 1 /*@"height"*/] doubleValue];
    }
    [self setResolution: res];
    
    _slots_valid = 0;
    //_slots_explicit = 0;
    _slots_default = 0;
    
    _machine_media = [d objectForKey: @"media"];

    _machine_data = d;
    
    [_root removeAllObjects];
    
    unsigned mask = 1;
    for (unsigned i = 0; i < SizeofKeys; ++i, mask <<= 1) {
        
        NSString *v = [_slot_object[i] objectForKey: @"value"];
        _slot_media[i] = nil;
        _slot_object[i] = nil;
        if (v) _slot_value[i] = v;

        NSArray *options = [d objectForKey: Keys[i]];
        if (!options) continue;
        
        _slots_valid |= mask;

        SlotItem *item = [SlotItem new];
        [item setIndex: i];
        [item setChildren: options];
        [item buildMenuWithSelectedValue: _slot_value[i]];
        
        if ([item defaultIndex] >= 0) {
            _slots_default |= mask;
        }
        // default media...
        _slot_media[i] = [item selectedMedia];
        [_root addObject: item];
    }
    
    
    
    [_outlineView reloadData];
    [self rebuildMedia];
    [self rebuildArgs];
}

-(void)setMachine: (NSString *)machine {
    if (_machine == machine) return;
    if (_machine && machine && [machine compare: _machine] == NSOrderedSame) return;
    _machine = machine;

    if (!machine) {
        [self resetMachine];
        return;
    }
    [self loadMachine];
}




-(void)rebuildMedia {


    #define _(var, o) var += [[o objectForKey: @ # var ] unsignedIntValue]
        
    unsigned cass = 0;
    unsigned cdrm = 0;
    unsigned hard = 0;
    unsigned flop_5_25 = 0;
    unsigned flop_3_5 = 0;

#if 0
    for (SlotItem *item in _root) {
        NSDictionary *tmp = [item selectedMedia];
        if (tmp) {
            _(cass, tmp);
            _(cdrm, tmp);
            _(hard, tmp);
            _(flop_5_25, tmp);
            _(flop_3_5, tmp);
        }
    }
#endif
#if 1
    unsigned mask = 1;
    for (unsigned i = 0; i < MAX_SLOTS; ++i, mask <<= 1) {
        
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
#endif
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


static NSString *SlotFlagForIndex(unsigned index){
     static NSString *Names[] = {
         @"-ramsize",
         @"-sl0",
         @"-sl1",
         @"-sl2",
         @"-sl3",
         @"-sl4",
         @"-sl5",
         @"-sl6",
         @"-sl7",
         @"-exp",
         @"-aux",
         @"-rs232",
         @"-gameio",
         @"-modem",
         @"-printer",
         // nubus mac
         @"-nb9",
         @"-nba",
         @"-nbb",
         @"-nbc",
         @"-nbd",
         @"-nbe",
     };
     static_assert(SIZEOF(Names) <= MAX_SLOTS, "flag overflow");
     return Names[index];
}

-(void)rebuildArgs {

    NSMutableArray *args = [NSMutableArray new];

    for (SlotItem *item in _root) {
        NSDictionary *d  = [item selectedItem];
        if ([(NSNumber *)[d objectForKey: @"default"] boolValue]) {
            continue; // default, don't include it.
        }
        NSString *value = [d objectForKey: @"value"];

        if (!value || ![value length]) {
            if (![item hasDefault]) continue;
            value = @"";
        }
        [args addObject: [item flag]];
        [args addObject: value];
    }
    
#if 0
    unsigned mask = 1;
    for (unsigned i = 0 ; i < MAX_SLOTS; ++i, mask <<= 1) {
        
        if (!(_slots_valid & mask)) continue;
        NSDictionary *d = _slot_object[i];
        
        if ([(NSNumber *)[d objectForKey: @"default"] boolValue]) {
            continue; // default, don't include it.
        }
        NSString *value = [d objectForKey: @"value"];
        
        if (!value) {
            // if slot has a default, need to overwrite it.
            if (!(_slots_default & mask)) continue;
            value = @"";
        }
        
        [args addObject: SlotFlagForIndex(i)];
        [args addObject: value];
    }
#endif
    [self setArgs: args];
}

- (IBAction)menuChanged:(NSPopUpButton *)sender {

    unsigned index = (unsigned)[sender tag];
    unsigned mask = 1 << index;


    // index 0 = ram = special case...
    
    NSDictionary *d = [[sender selectedItem] representedObject];

    _slots_explicit |= mask;
    _slot_value[index] = [d objectForKey: @"value"];
    //_slots_default &= ~mask;
    
    //_slot_object[index] = d;

    // media...
    NSDictionary *newMedia = [d objectForKey: @"media"];
    NSDictionary *oldMedia = _slot_media[index];
    
    if (newMedia != oldMedia) {
        _slot_media[index] = newMedia;
        [self rebuildMedia];
    }
    
    [self rebuildArgs];
}
-(IBAction)resetSlots:(id)sender {
    
    _slots_explicit = 0;
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {
        _slot_media[i] = nil;
        _slot_object[i] = nil;
        _slot_value[i] = nil;
    }
    for (SlotItem *item in _root) {
        [item reset];
        // if children, reset them too...
        unsigned index = [item index];
        _slot_media[index] = [item selectedMedia];
    }
    //[_outlineView reloadData]; // will need to reload if changing the default makes children disappear.

    [self rebuildMedia];
    [self rebuildArgs];
}

@end


@implementation NewSlotViewController (OutlineView)


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    if (!item) return [_root count];
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item) return [_root objectAtIndex: index];
    return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}



- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(SlotItem *)item {

    SlotTableCellView *v = [outlineView makeViewWithIdentifier: @"MenuCell" owner: self];

    [item prepareView: v];
    
    return v;
}



@end
