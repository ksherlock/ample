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

#define MAX_SLOTS 32


static unsigned RootKey = 0;


@interface SlotViewController ()
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSOutlineView *childOutlineView;

@end

@implementation SlotViewController {
    NSArray *_root;

    Media _slot_media[MAX_SLOTS];
    Media _machine_media;
    
    NSDictionary *_machine_data;

    NSMutableDictionary *_slotValues;
    
    IBOutlet NSPopover *_popover;
    
    BOOL _loadingBookmark;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    _root = @[];
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);

    _slotValues = [NSMutableDictionary new];

    //[_outlineView setIndentationPerLevel: 2.0];
}

-(void)resetMachine {

    _root = @[];
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);
    
    [_outlineView reloadData];

    [_slotValues removeAllObjects];
    
    _machine_media = EmptyMedia;
    _machine_data = nil;
    
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {
        _slot_media[i] = EmptyMedia;
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
    
    
    _machine_media = MediaFromDictionary([d objectForKey: @"media"]);

    _machine_data = d;
    
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {
        _slot_media[i] = EmptyMedia;
    }

    extern NSArray *BuildSlots(NSString *name, NSDictionary *data);
    _root = BuildSlots(_machine, d);
    objc_setAssociatedObject(_outlineView, &RootKey, _root, OBJC_ASSOCIATION_RETAIN);
    
    for (Slot *item in _root) {
        NSString *name = [item name];
        NSInteger index = [item index] - 1;
        if (index < 0 || index >= MAX_SLOTS) continue;

        if ([item type] == kSlotBIOS) continue;
        
        NSString *v = [_slotValues objectForKey: name];
        if (v) {
            [item selectValue: v];
        }
        // TODO -- reset to default index???

        _slot_media[index] = [item selectedMedia];
    }


    [_outlineView reloadData];
    if (!_loadingBookmark) {
        [self rebuildMedia];
        [self rebuildArgs];
    }
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
   
    Media media = EmptyMedia;
    
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {

        MediaAdd(&media, &_slot_media[i]);
    }
    // machine media last.
    MediaAdd(&media, &_machine_media);
    
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
    
    if (index < 0x10000) {
        direct = YES;
    } else {
        direct = NO;
        index &= ~0x10000;
    }
    index--;
    if (index < 0 || index >= MAX_SLOTS) return; //
    
    SlotOption *o = [[sender selectedItem] representedObject];
    Slot *item = [_root objectAtIndex: index];

    if (direct && [item type] != kSlotBIOS) {
        NSString *name = [item name];
        NSString *value = [o value];
        [_slotValues setObject: value forKey: name];
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
    if (index <= 0 || index >= 0x10000) return;
    index--;
    Slot *item = [_root objectAtIndex: index];

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
    
    
    //_slots_explicit = 0;
    for (unsigned i = 0; i < MAX_SLOTS; ++i) {
        _slot_media[i] = EmptyMedia;
    }
    for (Slot *item in _root) {
        NSString *name = [item name];
        
        [_slotValues removeObjectForKey: name];

        [item reset];
        // if children, reset them too...
        NSInteger index = [item index] - 1;
        if (index < 0) continue;
        _slot_media[index] = [item selectedMedia];
    }

#ifdef SLOT_TREE
    [_outlineView reloadData];
#endif
    if (!_loadingBookmark) {
        [self rebuildMedia];
        [self rebuildArgs];
    }
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


@implementation SlotViewController (Bookmark)


-(void)willLoadBookmark:(NSDictionary *)bookmark {
    _loadingBookmark = YES;
    [self setMachine: nil];
}
-(void)didLoadBookmark:(NSDictionary *)bookmark {
    _loadingBookmark = NO;

    [self rebuildArgs];
}

-(BOOL)loadBookmark: (NSDictionary *)bookmark {

    NSDictionary *dict = [bookmark objectForKey: @"slots"];
    
    [self setMachine: [bookmark objectForKey: @"machine"]];
    [self resetSlots: nil];

    for (Slot *item in _root) {
        [item reserialize: dict];
        
        NSInteger index = [item index] - 1;
        if (index >= 0 && index < MAX_SLOTS) {

            NSString *name = [item name];
            [_slotValues removeObjectForKey: name];

            if ([item defaultIndex] != [item selectedIndex]) {
                NSString *v = [item selectedValue];
                if (v) [_slotValues setObject: v forKey: name];
            }
        
            _slot_media[index] = [item selectedMedia];
        }
    }
    
    // need to do it here so it propogate to media view.
    [self rebuildMedia];
    return YES;
}
-(BOOL)saveBookmark: (NSMutableDictionary *)bookmark {

    NSMutableDictionary *slots = [NSMutableDictionary new];
    for (Slot *item in _root) {
        NSDictionary *d = [item serialize];
        [slots addEntriesFromDictionary: d];
    }

    [bookmark setObject: slots forKey: @"slots"];
    return YES;
}



@end
