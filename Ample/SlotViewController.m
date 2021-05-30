//
//  SlotViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/9/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//


#import "Ample.h"
#import "SlotViewController.h"
#import "Menu.h"
#import "Slot.h"
#import "Media.h"


#import <objc/runtime.h>

/* number of slot types.  bitmask used so should be < sizeof(unsigned *8) */
#define SLOT_COUNT 22
static_assert(SLOT_COUNT <= sizeof(unsigned) * 8, "too many slot types");

#define SIZEOF(x) (sizeof(x) / sizeof(x[0]))


static unsigned RootKey = 0;


@interface SlotViewController ()
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSOutlineView *childOutlineView;

@end

@implementation SlotViewController {
    NSArray *_root;

    unsigned _slots_explicit;
    unsigned _slots_valid;
    unsigned _slots_default;

    Slot *_slot_object[SLOT_COUNT];
    NSString *_slot_value[SLOT_COUNT]; // when explicitely set.

    Media _slot_media[SLOT_COUNT];
    Media _machine_media;
    
    NSDictionary *_machine_data;
        
    IBOutlet NSPopover *_popover;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    _root = @[];
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);


    //[_outlineView setIndentationPerLevel: 2.0];
}

-(void)resetMachine {

    _root = @[];
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);
    
    [_outlineView reloadData];

    _slots_valid = 0;
    _slots_explicit = 0;
    _slots_default = 0;
    _machine_media = EmptyMedia;
    _machine_data = nil;
    
    for (unsigned i = 0; i < SLOT_COUNT; ++i) {
        _slot_media[i] = EmptyMedia;
        _slot_object[i] = nil;
        _slot_value[i] = nil;
    }

    [self setResolution: NSMakeSize(0, 0)];
    [self setArgs: @[]];
    [self setMedia: EmptyMedia];
}


-(void)loadMachine {

    
    NSDictionary *d = MameMachine(_machine);
    

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
    
    _machine_media = MediaFromDictionary([d objectForKey: @"media"]);

    _machine_data = d;
    
    for (unsigned i = 0; i < SLOT_COUNT; ++i) {
        _slot_media[i] = EmptyMedia;
        _slot_object[i] = nil;
    }
    

    extern NSArray *BuildSlots(NSString *name, NSDictionary *data);
    _root = BuildSlots(_machine, d);
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);
    
    for (Slot *item in _root) {
        NSInteger index = [item index];
        if (index < 0) continue;
        unsigned mask = 1 << index;

        _slots_valid |= mask;
        if ([item defaultIndex] >= 0)
            _slots_default |= mask;
        
        if (_slot_value[index])
            [item selectValue: _slot_value[index]];
        
        _slot_media[index] = [item selectedMedia];
        _slot_object[index] = item;
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

    
    Media media = _machine_media;
    
    unsigned mask = 1;
    for (unsigned i = 0; i < SLOT_COUNT; ++i, mask <<= 1) {
        
        if (_slots_valid & mask) {
            MediaAdd(&media, &_slot_media[i]);
        }
    }

    [self setMedia: media];
}


-(void)rebuildArgs {

    NSMutableArray *args = [NSMutableArray new];

    for (Slot *item in _root) {
        
        NSArray *x = [item args];
        if (x) [args addObjectsFromArray: x];
    }

    [self setArgs: args];
}

- (IBAction)menuChanged:(NSPopUpButton *)sender {

    BOOL direct = YES;
    NSInteger index = [sender tag];
    if (index < 0) return; //
    
    if (index >= 0 && index < SLOT_COUNT) {
        direct = YES;
    } else {
        direct = NO;
        index &= ~0x10000;
    }
    if (index >= SLOT_COUNT) return; //
    unsigned mask = 1 << index;


    // index 0 = ram = special case...
    
    SlotOption *o = [[sender selectedItem] representedObject];
    Slot *item = _slot_object[index];

    if (direct) {
        _slots_explicit |= mask;
        _slot_value[index] = [o value];
        //_slots_default &= ~mask;
    }
    
    Media media = [item selectedMedia];
    if (!MediaEqual(&media, &_slot_media[index])) {
        _slot_media[index] = media;
        [self rebuildMedia];

    }

    // needs to reload children if expanded.
#ifdef SLOT_TREE
    if (direct) {
        BOOL rc = ([_outlineView isItemExpanded: item]);
        [_outlineView reloadItem: item reloadChildren: rc];
    }
#endif
    [self rebuildArgs];
}
- (IBAction)hamburger:(id)sender {

#if 0
    if ([_popover isShown]) {
        [_popover close];
    }
#endif
    
    NSInteger index = [sender tag];
    if (index < 0 || index >= SLOT_COUNT) return;
    
    Slot *item = _slot_object[index];

    NSArray *children = [item selectedChildren];
    objc_setAssociatedObject(_childOutlineView, &RootKey, children, OBJC_ASSOCIATION_RETAIN);
    if (!children) return;
    
    [_childOutlineView reloadData];
    NSSize size = [_popover contentSize];
    if (size.width < 200) size.width = 250;
    size = [_childOutlineView sizeThatFits: size];
    size.height += 40;
    [_popover setContentSize: size];
    
    [_popover showRelativeToRect: [sender bounds]
                          ofView: sender
                   preferredEdge: NSRectEdgeMaxY];
}

-(IBAction)resetSlots:(id)sender {
    
    _slots_explicit = 0;
    for (unsigned i = 0; i < SLOT_COUNT; ++i) {
        _slot_media[i] = EmptyMedia;
        _slot_value[i] = nil;
    }
    for (Slot *item in _root) {
        [item reset];
        // if children, reset them too...
        NSInteger index = [item index];
        if (index < 0) continue;
        _slot_media[index] = [item selectedMedia];
    }

#ifdef SLOT_TREE
    [_outlineView reloadData];
#endif
    [self rebuildMedia];
    [self rebuildArgs];
}

@end


@implementation SlotViewController (OutlineView)


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    NSArray *root = objc_getAssociatedObject(outlineView, &RootKey);
    if (!item) return [root count];
    
#ifdef SLOT_TREE
    NSArray *tmp = [(Slot *)item selectedChildren];
    return [tmp count];
#endif
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSArray *root = objc_getAssociatedObject(outlineView, &RootKey);

    if (!item) return [root objectAtIndex: index];
#ifdef SLOT_TREE
    NSArray *tmp = [(Slot *)item selectedChildren];
    return [tmp objectAtIndex: index];
#endif
    return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {

#ifdef SLOT_TREE
    if (!item) return NO;
     NSArray *tmp = [(Slot *)item selectedChildren];
    return [tmp count] > 0;
#else
    return NO;
#endif
}



- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(Slot *)item {

    SlotTableCellView *v = [outlineView makeViewWithIdentifier: @"MenuCell" owner: self];

    [item prepareView: v];
    
    return v;
}



@end
