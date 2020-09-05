//
//  MediaViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "MediaViewController.h"


@implementation TablePathView

@end


@protocol MediaNode
-(BOOL)isGroupItem;
-(BOOL)isExpandable;
-(NSInteger) count;

-(NSString *)viewIdentifier;
-(void)prepareView: (NSTableCellView *)view;
-(CGFloat)height;
@end

@interface MediaCategory : NSObject <MediaNode> {
        
}
@property NSInteger validCount;
@property NSArray *children; // URLs?
@property NSString *title;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;
@end

@interface MediaItem : NSObject <MediaNode>

@property NSURL *url;
@property BOOL valid;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;

-(void)invalidate;
@end



@implementation MediaCategory

-(instancetype)initWithTitle: (NSString *)title {
    [self setTitle: title];
    return self;
}
-(NSInteger) count {
    return [_children count];
}

-(id)objectAtIndex:(NSInteger)index {
    return [_children objectAtIndex: index];
}

-(BOOL)isGroupItem {
    return YES;
}

-(BOOL)isExpandable {
    return YES;
}

-(NSString *)viewIdentifier {
    return @"CategoryView";
}

-(void)prepareView: (NSTableCellView *)view {
    [[view textField] setStringValue: _title];
}

-(CGFloat)height {
    return 17;
}


-(BOOL)setItemCount: (unsigned)newCount {

    if (newCount == _validCount) {
        return NO;
    }

    unsigned count = (unsigned)[_children count];
    NSMutableArray *tmp = [NSMutableArray arrayWithArray: _children];

    _validCount = newCount;

    for (unsigned i = count; i < newCount; ++i) {
        [tmp addObject: [MediaItem new]];
    }
    // delete excess items, if blank.  otherwise, mark invalid.
    unsigned ix = 0;
    for(MediaItem *item in tmp) {
        [item setValid: ix++ < newCount];
    }

    for (unsigned i = newCount; i < count; ++i) {
        MediaItem *item = [tmp lastObject];
        if ([item url]) break;
        
        [tmp removeLastObject];
    }
    
    [self setChildren: tmp];
    return YES;
}

-(BOOL)pruneChildren {
    NSUInteger count = [_children count];
    BOOL delta = NO;
    if (_validCount == count) return NO;

    NSMutableArray *tmp = [NSMutableArray arrayWithArray: _children];
    for (NSInteger i = _validCount; i < count; ++i) {
        MediaItem *item = [tmp lastObject];
        if ([item url]) break;
    
        [tmp removeLastObject];
        delta = YES;
    }
    if (delta) {
        [self setChildren: tmp];
        return YES;
    }
    return NO;
}
@end



@implementation MediaItem

-(instancetype)initWithURL: (NSURL *)url {
    [self setUrl: url];
    return self;
}

-(NSInteger) count {
    return 0;
}

-(id)objectAtIndex:(NSInteger)index {
    return nil;
}

-(BOOL)isGroupItem {
    return NO;
}

-(BOOL)isExpandable {
    return NO;
}

-(NSString *)viewIdentifier {
    return @"ItemView";
}

-(void)prepareView: (TablePathView *)view {
    NSPathControl *pc = [view pathControl];
    NSButton *button = [view ejectButton];

    [pc unbind: @"value"];
    [pc bind: @"value" toObject: self withKeyPath: @"url" options: nil];
    
    [button unbind: @"enabled"];
    NSValueTransformer *t = [NSValueTransformer valueTransformerForName: NSIsNotNilTransformerName];
    NSDictionary *options = @{ NSValueTransformerBindingOption: t};
    [button bind: @"enabled" toObject: self withKeyPath: @"url" options: options];
    
    NSColor *tintColor = nil;
    if (!_valid) tintColor = [NSColor redColor];
    [button setContentTintColor: tintColor];
}

-(CGFloat)height {
    return 27;
}

-(void)invalidate {
    _valid = NO;
}
@end

@interface MediaViewController () {

    MediaCategory *_data[5];
    NSArray *_root;
    NSDictionary *_media;
}

@end

@implementation MediaViewController

-(void)awakeFromNib {
    
    static unsigned first = 0;
    
    if (first) return;
    first++;

    MediaCategory *a, *b, *c, *d, *e;
    
    a = [[MediaCategory alloc] initWithTitle: @"5.25\" Floppies"];
    b = [[MediaCategory alloc] initWithTitle: @"3.5\" Floppies"];
    c = [[MediaCategory alloc] initWithTitle: @"Hard Drives"];
    d = [[MediaCategory alloc] initWithTitle: @"CD-ROMs"];
    e = [[MediaCategory alloc] initWithTitle: @"Casettes"];

    
    _data[0] = a;
    _data[1] = b;
    _data[2] = c;
    _data[3] = d;
    _data[4] = e;

    _root = @[];

}


enum {
    kIndexFloppy_5_25 = 0,
    kIndexFloppy_3_5,
    kIndex_HardDrive,
    kIndexCDROM,
    kIndexCassette
};

-(void)rebuildArgs {
    
    static char* prefix[] = {
        "flop", "flop", "hard", "cdrm", "cass"
    };
    NSMutableArray *args = [NSMutableArray new];
    
    unsigned counts[5] = { 0, 0, 0, 0, 0 };
    
    for (unsigned j = 0; j < 5; ++j) {
    
        MediaCategory *cat = _data[j];
        NSInteger valid = [cat validCount];
        for (NSInteger i = 0; i < valid; ++i) {
            counts[j]++;

            MediaItem *item = [cat objectAtIndex: i];
            NSURL *url = [item url];
            if (!url) continue;
            [args addObject: [NSString stringWithFormat: @"-%s%u", prefix[j], counts[j]]];
            NSString *s = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
            
            [args addObject: s];
        }
        if (j == 0) counts[1] = counts[0]; // 3.5/5.25
    }
    
    [self setArgs: args];
}

-(void)rebuildRoot {
    NSMutableArray *tmp = [NSMutableArray new];
    for (unsigned j = 0 ; j < 5; ++j) {
        MediaCategory *cat = _data[j];
        if ([cat count]) [tmp addObject: cat];
    }
    _root = tmp;
    //[_outlineView reloadItem: nil reloadChildren: YES];

    [_outlineView reloadData];
    [_outlineView expandItem: nil expandChildren: YES];
}

-(void)setMedia: (NSDictionary *)media {
    
    static NSString *Keys[] = {
        @"flop_5_25",
        @"flop_3_5",
        @"hard",
        @"cdrm",
        @"cass"
    };

    NSNumber *o;
    MediaCategory *cat;
    unsigned i;
    BOOL delta = NO;
    
    
    if (_media == media) return;
    _media = media;
    
    for (unsigned j = 0; j < 5; ++j) {
    
        o = [media objectForKey: Keys[j]];
        i = [o unsignedIntValue];
        cat = _data[j];
        delta |= [cat setItemCount: i];
    }

    
    if (delta) {
        [self rebuildRoot];
        [self rebuildArgs];
    }
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //NSOutlineView *view = [self view];
    //[view expandItem: nil expandChildren: YES];
    // Do view setup here.

    [_outlineView reloadData];
    [_outlineView expandItem: nil expandChildren: YES];
}

#pragma mark - NSOutlineViewDelegate


- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

//- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item;

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id<MediaNode>)item {
    
    NSString *ident = [item viewIdentifier];
    if (!ident) return nil;
    NSTableCellView *v = [outlineView makeViewWithIdentifier: ident owner: self];
    [(id<MediaNode>)item prepareView: v];
    return v;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id<MediaNode>)item {
    return [item isExpandable];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return NO; //[item isGroupItem];
}




- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}

/*
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}
*/


-(BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    return NO;
}


- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    //return nil;
    return [[item cellClass] new];
}




#pragma mark - NSOutlineViewDataSource

// nil item indicates the root.


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return [_root count];
    return [item count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (item == nil) {
        return [_root objectAtIndex: index];
    }
    return [item objectAtIndex: index];
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id<MediaNode>)item {
    return [item height];
}


#pragma mark - IBActions
- (IBAction)ejectAction:(id)sender {
    
    NSInteger row = [_outlineView rowForView: sender];
    if (row < 0) return;

    //TablePathView *pv = [_outlineView viewAtColumn: 0 row: row makeIfNecessary: NO];
    MediaItem *item = [_outlineView itemAtRow: row];
    [item setUrl: nil];
    //[[pv pathControl] setURL: nil];
    
    // if item is invalid, should attempt to remove...
    if (![item valid]) {
        MediaCategory *cat = [_outlineView parentForItem: item];
        if ([cat pruneChildren]) [self rebuildRoot];
    }
    [self rebuildArgs];
}

- (IBAction)pathAction:(id)sender {
    // need to update the eject button...
    [self rebuildArgs];
}
@end
