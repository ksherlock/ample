//
//  MediaViewController.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "MediaViewController.h"

@interface MediaCategory : NSObject {
        
}
@property NSInteger validCount;
@property NSArray *children; // URLs?
@property NSString *title;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;
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


-(void)prepareCell: (id)cell {
    [(NSTextFieldCell *)cell setTitle: _title];
}
@end


@interface MediaItem : NSObject {
    
}
@property NSURL *url;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;
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

-(void)prepareCell: (id)cell {
    [(NSTextFieldCell *)cell setTitle: @"xxx"];
}



@end

@interface MediaViewController () {

    MediaCategory *_data[4];
    NSArray *_root;
}

@end

@implementation MediaViewController

-(void)awakeFromNib {
    
    MediaCategory *a, *b, *c, *d;
    
    a = [[MediaCategory alloc] initWithTitle: @"5.25\" Floppies"];
    b = [[MediaCategory alloc] initWithTitle: @"3.5\" Floppies"];
    c = [[MediaCategory alloc] initWithTitle: @"Hard Drives"];
    d = [[MediaCategory alloc] initWithTitle: @"Casettes"];

    
    _data[0] = a;
    _data[1] = b;
    _data[2] = c;
    _data[3] = d;
    _root = @[a,b,c,d];
    
    
    [a setChildren: @[
        [MediaItem new],
        [MediaItem new],
    ]];

    [b setChildren: @[
        [MediaItem new],
        [MediaItem new],
    ]];

    [c setChildren: @[
        [MediaItem new],
        [MediaItem new],
    ]];

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //NSOutlineView *view = [self view];
    //[view expandItem: nil expandChildren: YES];
    // Do view setup here.
}

#pragma mark - NSOutlineViewDelegate

#if 0
- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

//- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item;

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
    //NSView *v = [outlineView makeViewWithIdentifier:<#(nonnull NSUserInterfaceItemIdentifier)#> owner: self];
    
    NSView *v = [[NSView alloc]initWithFrame: NSZeroRect];
    
    return v;
}
#endif

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isExpandable];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isGroupItem];
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    [item prepareCell: cell];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}



- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return nil;
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



@end
