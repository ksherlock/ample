//
//  MediaViewController.m
//  MA2ME
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

-(Class)cellClass {
    return [NSTextFieldCell class];
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
@end


@interface MediaItem : NSObject <MediaNode> {
    
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
    [(NSPathCell *)cell setURL: _url];
    [(NSPathCell *)cell setPathStyle: NSPathStylePopUp];
//    [(NSTextFieldCell *)cell setTitle: @"xxx"];
}

-(Class)cellClass {
    return [NSPathCell class];
}

-(NSString *)viewIdentifier {
    return @"ItemView";
}

-(void)prepareView: (TablePathView *)view {
    NSPathControl *pc = [view pathControl];

#if 0
    Class pcClass = [NSPathControl class];
    if (!pc) {
        for (NSView *v in [view subviews]) {
            if ([v isKindOfClass: pcClass]) {
                pc = v;
                [view setPathControl: pc];
                break;
            }
        }
    }
    if (!pc) return;
#endif
    [pc setURL: _url]; //??? will binding take care of it?
    [pc unbind: @"value"];
    [pc bind: @"value" toObject: self withKeyPath: @"url" options: nil];
}

-(CGFloat)height {
    return 27;
}


@end

@interface MediaViewController () {

    MediaCategory *_data[4];
    NSArray *_root;
}
@property (weak) IBOutlet NSPathControl *_hacky_hack;

@end

@implementation MediaViewController

-(void)awakeFromNib {
    
    static unsigned first = 0;
    
    if (first) return;
    first++;

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
    return [item isGroupItem];
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    [item prepareCell: cell];
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
- (IBAction)buttonDelete:(id)sender {
    
    NSInteger row = [_outlineView rowForView: sender];
    if (row < 0) return;

    //TablePathView *pv = [_outlineView viewAtColumn: 0 row: row makeIfNecessary: NO];
    MediaItem *item = [_outlineView itemAtRow: row];
    [item setUrl: nil];
    //[[pv pathControl] setURL: nil];
}
@end
