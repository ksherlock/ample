//
//  MediaViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "MediaViewController.h"
#import "TableCellView.h"


@protocol MediaNode
-(BOOL)isGroupItem;
-(BOOL)isExpandable;
-(NSInteger) count;

-(NSString *)viewIdentifier;
-(void)prepareView: (NSTableCellView *)view;
-(CGFloat)height;
-(NSInteger)index;
@end

@interface MediaCategory : NSObject <MediaNode> {
        
}
@property NSInteger validCount;
@property NSMutableArray *children; // URLs?
@property NSString *title;
@property NSInteger index;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;
@end

@interface MediaItem : NSObject <MediaNode>

@property NSURL *url;
@property BOOL valid;
@property NSInteger index;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;

-(void)invalidate;
@end



@implementation MediaCategory

+(instancetype)categoryWithTitle: (NSString *)title {
    return [[self alloc] initWithTitle: title];
}

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

}

-(CGFloat)height {
    return 17;
}


-(BOOL)setItemCount: (unsigned)newCount {

    if (newCount == _validCount) {
        return NO;
    }

    unsigned count = (unsigned)[_children count];

    _validCount = newCount;
    if (!_children) _children = [NSMutableArray new];

    for (unsigned i = count; i < newCount; ++i) {
        MediaItem *item = [MediaItem new];
        [item setIndex: i];
        [_children addObject: item];
    }

    // delete excess items, if blank.  otherwise, mark invalid.
    unsigned ix = 0;
    for(MediaItem *item in _children) {
        [item setValid: ix++ < newCount];
    }

    for (unsigned i = newCount; i < count; ++i) {
        MediaItem *item = [_children lastObject];
        if ([item url]) break;
        
        [_children removeLastObject];
    }
    
    return YES;
}

-(BOOL)pruneChildrenWithOutlineView: (NSOutlineView *)view {
    NSUInteger count = [_children count];
    BOOL delta = NO;
    if (_validCount == count) return NO;
    NSMutableIndexSet *set = [NSMutableIndexSet new];

    for (NSInteger i = _validCount; i < count; ++i) {
        MediaItem *item = [_children lastObject];
        if ([item url]) break;
    
        [_children removeLastObject];
        [set addIndex: [_children count]];

        delta = YES;
    }
    if (delta) {

        if (view)
            [view removeItemsAtIndexes: set inParent: self withAnimation: NSTableViewAnimationEffectFade];

        return YES;
    }
    return NO;
}

-(BOOL)moveItemFrom: (NSInteger)oldIndex to: (NSInteger)newIndex outlineView: (NSOutlineView *)view {
    if (newIndex == oldIndex) return NO;
    NSUInteger count = [_children count];
    if (oldIndex >= count) return NO;

    MediaItem *item = [_children objectAtIndex: oldIndex];
    [_children removeObjectAtIndex: oldIndex];
    if (newIndex > oldIndex) newIndex--;
    if (newIndex >= count) {
        [_children addObject: item];
    } else {
        [_children insertObject: item atIndex: newIndex];
    }
    if (view) [view moveItemAtIndex: oldIndex inParent: self toIndex: newIndex inParent: self];

    // re-index and re-validate.
    unsigned ix = 0;
    for (MediaItem *item in _children) {
        [item setIndex: ix];
        [item setValid: ix < _validCount];
        
//        [view reloadItem: item];
        
        ++ix;
    }
    [self pruneChildrenWithOutlineView: view];
    //[view reloadItem: self reloadChildren: YES];
    return YES;
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
    
}

-(CGFloat)height {
    return 27;
}

-(void)invalidate {
    if (!_valid) return;
    [self setValid: NO];
}
@end


#define CATEGORY_COUNT 6
#define SIZEOF(x) (sizeof(x) / sizeof(x[0]))

@interface MediaViewController () {

    MediaCategory *_data[CATEGORY_COUNT];
    NSArray *_root;
    Media _media;
    
    BOOL _loadingBookmark;
}

@end

@implementation MediaViewController

enum {
    kIndexFloppy525 = 0,
    kIndexFloppy35,
    kIndexHardDrive,
    kIndexCDROM,
    kIndexCassette,
    kIndexDiskImage,
};


-(void)awakeFromNib {
    
    static unsigned first = 0;
    
    if (first) return;
    first++;

    _data[kIndexFloppy525] = [MediaCategory categoryWithTitle: @"5.25\" Floppies"];
    _data[kIndexFloppy35] = [MediaCategory categoryWithTitle: @"3.5\" Floppies"];
    _data[kIndexHardDrive] = [MediaCategory categoryWithTitle: @"Hard Drives"];
    _data[kIndexCDROM] = [MediaCategory categoryWithTitle: @"CD-ROMs"];
    _data[kIndexCassette] = [MediaCategory categoryWithTitle: @"Cassettes"];
    _data[kIndexDiskImage] = [MediaCategory categoryWithTitle: @"Hard Disk Images"]; // Mac Nubus psuedo image device

    _root = @[];

}



-(void)rebuildArgs {
    
    static char* prefix[] = {
        "flop", "flop", "hard", "cdrm", "cass", "disk"
    };
    static_assert(SIZEOF(prefix) == CATEGORY_COUNT, "Missing item");
    NSMutableArray *args = [NSMutableArray new];
    
    unsigned counts[CATEGORY_COUNT] = { 0 };
    
    for (unsigned j = 0; j < CATEGORY_COUNT; ++j) {
    
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
    int ix = 0;
    for (unsigned j = 0 ; j < CATEGORY_COUNT; ++j) {
        MediaCategory *cat = _data[j];
        [cat setIndex: -1];
        if ([cat count]) {
            [cat setIndex: ix++];
            [tmp addObject: cat];
        }
    }
    _root = tmp;

    // todo - switch this to use removeItemsAtIndexes:inParent:withAnimation:
    // and insertItemsAtIndexes:inParent:withAnimation:
    
    if (!_loadingBookmark) {
        [_outlineView reloadData];
        [_outlineView expandItem: nil expandChildren: YES];
    }
}

-(void)setMedia: (Media)media {
    
    MediaCategory *cat;
    BOOL delta = NO;
    unsigned x;

    if (MediaEqual(&_media, &media)) return;
    _media = media;
    
    
#undef _
#define _(name, index) \
x = media.name; cat = _data[index]; delta |= [cat setItemCount: x]
    _(cass, kIndexCassette);
    _(cdrom, kIndexCDROM);
    _(hard, kIndexHardDrive);
    _(floppy_3_5, kIndexFloppy35);
    _(floppy_5_25, kIndexFloppy525);
    _(pseudo_disk, kIndexDiskImage);


    if (delta) {
        [self rebuildRoot];
        if (!_loadingBookmark) [self rebuildArgs];
    }
}

-(void)resetDiskImages {

    BOOL delta = NO;
    for (unsigned j = 0; j < CATEGORY_COUNT; ++j) {
    
        MediaCategory *cat = _data[j];
        NSInteger count = [cat count];
        for (NSInteger i = 0; i < count; ++i) {

            MediaItem *item = [cat objectAtIndex: i];
            NSURL *url = [item url];
            if (!url) continue;
            [item setUrl: nil];
            delta = YES;
        }
        if ([cat pruneChildrenWithOutlineView: _outlineView]) delta = YES;
    }
    if (delta) {
        [self rebuildRoot];
        if (!_loadingBookmark) [self rebuildArgs];
    }
}

static NSString *kDragType = @"private.ample.media";
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //NSOutlineView *view = [self view];
    //[view expandItem: nil expandChildren: YES];
    // Do view setup here.

    [_outlineView reloadData];
    [_outlineView expandItem: nil expandChildren: YES];
    
    [_outlineView registerForDraggedTypes: @[kDragType]];
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
    [v setObjectValue: item];

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

#if 0
- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id<MediaNode>)item {

    if ([item isGroupItem]) return nil;
    
    NSPasteboardItem *pb = [NSPasteboardItem new];
    
    return pb;
}
#endif

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    if ([items count] > 1) return NO;
    
    //NSLog(@"%s", sel_getName(_cmd));
    
    MediaItem *item = [items firstObject];
    
    if (![item isKindOfClass: [MediaItem class]]) return NO;
    
    // find the category. only allow if more than 1 item in the category.
    
    MediaCategory *cat = nil;
    
    
    for (MediaCategory *c in _root) {
        NSUInteger ix = [[c children] indexOfObject: item];
        if (ix != NSNotFound){
            cat = c;
            break;
        }
    }
    if (!cat) return NO;
    if ([cat count] < 2) return NO;

    NSInteger indexes[2] =  { 0, 0 };
    indexes[0] = [cat index];
    indexes[1] = [item index];
    NSData *data = [NSData dataWithBytes: indexes length: sizeof(indexes)];

    [pasteboard setData: data forType: kDragType];
    return YES;
}

/*
 * IF item is present, it's a MediaCategory and index is the index of the MediaItem it would be inserted as.
 * IF item is nil, index is the MediaCategory index, which should be converted to moving to the end.
 * IF index < 0,  dragging far beyond the category list, so NOPE it.
 *
 */
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {

    if (index < 0) return NSDragOperationNone;

    
    NSPasteboard *pb = [info draggingPasteboard];
    NSData *data = [pb dataForType: kDragType];
    
    if (!data) return NSDragOperationNone;

    NSInteger indexes[2];
    if ([data length] != sizeof(indexes)) return NSDragOperationNone;
    [data getBytes: &indexes length: sizeof(indexes)];
    
    //NSLog(@"%d - %d", (int)indexes[0], (int)indexes[1]);
    
    MediaCategory *cat = item;
    if (!item) {
        // move to the END of the previous category.
        if (index == 0) return NSDragOperationNone;
        cat = [_root objectAtIndex: index - 1];
        index = [cat count]; // -1; - interferes w/ -1 logic below.
    }

    //NSLog(@"%d - %d", (int)[(MediaCategory *)item index], (int)index);


    if ([cat index] != indexes[0]) return NSDragOperationNone;
    if (indexes[1] == index) return NSDragOperationNone;
    if (indexes[1] == index-1) return NSDragOperationNone;
    return NSDragOperationMove;
        
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
 
    if (index < 0) return NO;

    
    NSPasteboard *pb = [info draggingPasteboard];
    NSData *data = [pb dataForType: kDragType];
    
    if (!data) return NSDragOperationNone;

    NSInteger indexes[2];
    if ([data length] != sizeof(indexes)) return NO;
    [data getBytes: &indexes length: sizeof(indexes)];
    
    //NSLog(@"%d - %d", (int)indexes[0], (int)indexes[1]);
    
    MediaCategory *cat = item;
    
    if (!item) {
        // move to the END of the previous category.
        if (index == 0) return NO;
        cat = [_root objectAtIndex: index - 1];
        index = [cat count]; // -1; - interferes w/ -1 logic below.
    }

    //NSLog(@"%d - %d", (int)[(MediaCategory *)item index], (int)index);


    if ([cat index] != indexes[0]) return NO;
    if (indexes[1] == index) return NO;
    if (indexes[1] == index-1) return NO;
    
    NSInteger oldIndex = indexes[1];

    [_outlineView beginUpdates];
    [cat moveItemFrom: oldIndex to: index outlineView: _outlineView];
    [_outlineView endUpdates];
    [self rebuildArgs];

    //[_outlineView reloadItem: cat reloadChildren: YES];
    return YES;

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
        [_outlineView beginUpdates];
        [cat pruneChildrenWithOutlineView: _outlineView];
        [_outlineView endUpdates];
    }
    
    // todo -- if this eliminates a category completely, it will still be included
    // since we're now using animaations instead of reloading.
    
    [self rebuildArgs];
}

- (IBAction)pathAction:(id)sender {
    // need to update the eject button...
    
    NSURL *url = [(NSPathControl *)sender URL];
    
    if (url) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: @"DiskImageAdded" object: url];
    }
    
    [self rebuildArgs];
}

-(IBAction)resetMedia:(id)sender {
    [self resetDiskImages];
}

@end

@implementation MediaViewController (Bookmark)

-(void)willLoadBookmark:(NSDictionary *)bookmark {
    _loadingBookmark = YES;
    [self resetDiskImages];
}
-(void)didLoadBookmark:(NSDictionary *)bookmark {
    _loadingBookmark = NO;


    [self rebuildRoot];
    [self rebuildArgs];
}


-(BOOL)loadBookmark: (NSDictionary *)bookmark {

    
    // if order of indexes change, would need to do a version check.
    
    NSArray *media = [bookmark objectForKey: @"media"];
    unsigned ix = 0;
    for (NSArray *a in media) {
        if (ix >= CATEGORY_COUNT) {
            NSLog(@"MediaViewController: too many categories.");
            break;
        }
        MediaCategory *cat = _data[ix++];
        NSInteger count = [cat count];
        unsigned i = 0;
        for (NSString *path in a) {
            if (i >= count) {
                NSLog(@"MediaViewController: too many files.");
                break; //
            }
            MediaItem *item = [cat objectAtIndex: i++];
            NSURL *url = nil;
            if ([path length])
                url = [NSURL fileURLWithPath: path];

            [item setUrl: url];
        }
    }
    return YES;

}

-(BOOL)saveBookmark: (NSMutableDictionary *)bookmark {

    NSMutableArray *media = [NSMutableArray arrayWithCapacity: CATEGORY_COUNT];

    for (unsigned ix = 0; ix < CATEGORY_COUNT; ++ix) {
    
        MediaCategory *cat = _data[ix];
        NSInteger count = [cat validCount];
        
        NSMutableArray *array = [NSMutableArray new];
        for (NSInteger i = 0; i < count; ++i) {

            MediaItem *item = [cat objectAtIndex: i];
            NSURL *url = [item url];
            NSString *s = @"";
            if (url)
                s = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
            
            [array addObject: s];
        }
        [media addObject: array];
    }
    
    [bookmark setObject: media forKey: @"media"];
    
    return YES;
}


@end
