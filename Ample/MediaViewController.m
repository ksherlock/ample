//
//  MediaViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "MediaViewController.h"
#import "TableCellView.h"

#define SIZEOF(x) (sizeof(x) / sizeof(x[0]))


@protocol MediaNode
-(BOOL)isGroupItem;
-(BOOL)isExpandable;
-(NSInteger)count;
-(NSInteger)category;

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
@property NSInteger category;
@property (weak)NSOutlineView *view;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
-(BOOL)isGroupItem;
@end

@interface MediaItem : NSObject <MediaNode>

@property NSString *string;
@property NSURL *url;
@property BOOL valid;
@property NSInteger index;
@property NSInteger category;

@property (readonly) BOOL occupied;

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
        [item setCategory: _category];
        [_children addObject: item];
    }

    // delete excess items, if blank.  otherwise, mark invalid.
    unsigned ix = 0;
    for(MediaItem *item in _children) {
        [item setValid: ix++ < newCount];
    }

    for (unsigned i = newCount; i < count; ++i) {
        MediaItem *item = [_children lastObject];
        if ([item occupied]) break;
        
        [_children removeLastObject];
    }
    
    return YES;
}

-(BOOL)addURL: (NSURL *)url {

    for (MediaItem *item in _children) {
        if (![item occupied]) {
            [item setUrl: url];
            return NO;
        }
    }
    // add an extra item...

    if (!_children) _children = [NSMutableArray new];
    NSUInteger ix = [_children count];

    MediaItem *item = [MediaItem new];
    [item setIndex: ix];
    [item setCategory: _category];
    [item setUrl: url];
    [item setValid: ix < _validCount];
    [_children addObject: item];
    if (_view) {
        NSIndexSet *set = [NSIndexSet indexSetWithIndex: ix];
        [_view insertItemsAtIndexes: set
                          inParent: self
                     withAnimation: NSTableViewAnimationEffectFade];
    }

    return YES;
}

-(BOOL)pruneChildren {
    NSUInteger count = [_children count];
    BOOL delta = NO;
    if (_validCount == count) return NO;
    NSMutableIndexSet *set = [NSMutableIndexSet new];

    for (NSInteger i = _validCount; i < count; ++i) {
        MediaItem *item = [_children lastObject];
        if ([item occupied]) break;
    
        [_children removeLastObject];
        [set addIndex: [_children count]];

        delta = YES;
    }
    if (delta) {

        if (_view)
            [_view removeItemsAtIndexes: set inParent: self withAnimation: NSTableViewAnimationEffectFade];

        return YES;
    }
    return NO;
}

-(BOOL)moveItemFrom: (NSInteger)oldIndex to: (NSInteger)newIndex {
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
    if (_view) [_view moveItemAtIndex: oldIndex inParent: self toIndex: newIndex inParent: self];

    // re-index and re-validate.
    unsigned ix = 0;
    for (MediaItem *item in _children) {
        [item setIndex: ix];
        [item setValid: ix < _validCount];
        
//        [view reloadItem: item];
        
        ++ix;
    }
    [self pruneChildren];
    //[view reloadItem: self reloadChildren: YES];
    return YES;
}
@end

@implementation MediaItem



-(instancetype)initWithURL: (NSURL *)url {
    _url = url;
    return self;
}

-(instancetype)initWithString: (NSString *)string {
    _string = string;
    return self;
}

-(NSString *)argument {
    if (_string)
        return _string;

    // todo -- have setURL also update _string?
    if (_url)
        return [NSString stringWithCString: [_url fileSystemRepresentation] encoding: NSUTF8StringEncoding];

    return nil;
}

+(NSSet *)keyPathsForValuesAffectingOccupied {
    return [NSSet setWithObjects: @"url", @"string", nil];
}

-(BOOL)occupied {
    return _url || _string;
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
    if (_category == kIndexBitBanger) return @"BBItemView";
    if (_category == kIndexMidiOut) return @"MidiItemView";
    if (_category == kIndexMidiIn) return @"MidiItemView";
    return @"ItemView";
}

-(void)prepareView: (MediaTableCellView *)view {
    /* set the path tag = category. */

    [view prepareView: _category];
#if 0
    if (_category == kIndexMidiIn || _category == kIndexMidiOut || _category == kIndexBitBanger) {
        return;
    }
    
    NSPathControl *pc = [view pathControl];
    [pc setTag: _category + 1]; // to differentiate 0 / no path control.
#endif
}

-(CGFloat)height {
    return 27;
}

-(void)invalidate {
    if (!_valid) return;
    [self setValid: NO];
}
@end




@interface MediaViewController () {

    MediaCategory *_data[CATEGORY_COUNT];
    NSMutableArray *_root;
    Media _media;
    
    BOOL _loadingBookmark;
}

@end

@implementation MediaViewController



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
    _data[kIndexBitBanger] = [MediaCategory categoryWithTitle: @"Serial Bit Banger"]; // null_modem

    _data[kIndexMidiIn] = [MediaCategory categoryWithTitle: @"MIDI (In)"];
    _data[kIndexMidiOut] = [MediaCategory categoryWithTitle: @"MIDI (Out)"];
    _data[kIndexPicture] = [MediaCategory categoryWithTitle: @"Picture"];

    for (unsigned i = 0; i < CATEGORY_COUNT; ++i) {
        [_data[i] setCategory: i];
        [_data[i] setIndex: -1];
    }
    
    _root = [NSMutableArray new];

}



-(void)rebuildArgs {
    
    static char* prefix[] = {
        "flop", "flop", "hard", "cdrm", "cass", "disk", "bitb", "min", "mout", "pic"
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
            NSString *arg = [item argument];

            if (arg) {
                [args addObject: [NSString stringWithFormat: @"-%s%u", prefix[j], counts[j]]];
                [args addObject: arg];
            }
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
    
    // todo -- fancy diff algorithm to animate changes.
    
    MediaCategory *cat;
    BOOL delta = NO;
    unsigned x;

    if (MediaEqual(&_media, &media)) return;
    _media = media;
    
    [_outlineView beginUpdates];

    
#undef _
#define _(name, index) \
x = media.name; cat = _data[index]; delta |= [cat setItemCount: x]
    _(cass, kIndexCassette);
    _(cdrom, kIndexCDROM);
    _(hard, kIndexHardDrive);
    _(floppy_3_5, kIndexFloppy35);
    _(floppy_5_25, kIndexFloppy525);
    _(pseudo_disk, kIndexDiskImage);
    _(bitbanger, kIndexBitBanger);
    // disable midi for now - it's either a midi file (which auto-plays too soon to be useful)
    // or a midi device ("default" for first one).
    // So we should build a device list (and pre-populate the default one)
    // another approach is a separate utility to act as a midi/serial input converter
    // and midi file / serial converter so the modem/serial port could be used.
#if 1
    _(midiin, kIndexMidiIn);
    _(midiout, kIndexMidiOut);
#endif
    _(picture, kIndexPicture);


    if (delta) {
        [self rebuildRoot];
        if (!_loadingBookmark) [self rebuildArgs];
    }

    [_outlineView endUpdates];
}

-(void)resetDiskImages {

    BOOL delta = NO;
    for (unsigned j = 0; j < CATEGORY_COUNT; ++j) {
    
        MediaCategory *cat = _data[j];
        NSInteger count = [cat count];
        for (NSInteger i = 0; i < count; ++i) {

            MediaItem *item = [cat objectAtIndex: i];
            if (![item occupied]) continue;
            [item setUrl: nil];
            [item setString: nil];
            delta = YES;
        }
        if ([cat pruneChildren]) delta = YES;
    }
    if (delta) {
        [self rebuildRoot];
        if (!_loadingBookmark) [self rebuildArgs];
    }
}

static NSString *kDragType = @"private.ample.media";
- (void)viewDidLoad {

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [super viewDidLoad];
    
    //NSOutlineView *view = [self view];
    //[view expandItem: nil expandChildren: YES];
    // Do view setup here.

    [_outlineView reloadData];
    [_outlineView expandItem: nil expandChildren: YES];
    
    [_outlineView registerForDraggedTypes: @[kDragType]];

    for (unsigned i = 0; i < CATEGORY_COUNT; ++i)
        [_data[i] setView: _outlineView];


    [nc addObserver: self selector: @selector(magicRouteNotification:) name: kNotificationDiskImageMagicRoute object: nil];

}

-(void)viewWillDisappear {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
    for (unsigned i = 0; i < CATEGORY_COUNT; ++i)
        [_data[i] setView: nil];
}

#pragma mark - NSOutlineViewDelegate


- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    
}

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
    [cat moveItemFrom: oldIndex to: index];
    [_outlineView endUpdates];
    [self rebuildArgs];

    //[_outlineView reloadItem: cat reloadChildren: YES];
    return YES;

}




#pragma mark - IBActions
- (IBAction)ejectAction:(id)sender {
    
    NSInteger row = [_outlineView rowForView: sender];
    if (row < 0) return;

    MediaItem *item = [_outlineView itemAtRow: row];
    [item setUrl: nil];
    [item setString: nil];
    
    // if item is invalid, should attempt to remove...
    if (![item valid]) {
        MediaCategory *cat = [_outlineView parentForItem: item];
        [_outlineView beginUpdates];
        [cat pruneChildren];
        
        // remove the entire category??
        if (![cat validCount] && ![cat count]) {
            NSUInteger ix = [_root indexOfObject: cat];
            if (ix != NSNotFound) {
                NSIndexSet *set = [NSIndexSet indexSetWithIndex: ix];
                [_outlineView removeItemsAtIndexes: set
                                          inParent: nil
                                     withAnimation: NSTableViewAnimationEffectFade];

                [_root removeObjectAtIndex: ix];
                [cat setIndex: -1];
            }
        }
        
        [_outlineView endUpdates];
    }
    
    [self rebuildArgs];
}

- (IBAction)pathAction:(id)sender {
    
    NSURL *url = [(NSPathControl *)sender URL];
    NSInteger tag = [sender tag] - 1;
    
    switch(tag) {

        case kIndexFloppy525:
        case kIndexFloppy35:
        case kIndexHardDrive:
        case kIndexCDROM:
        case kIndexCassette:
        case kIndexDiskImage:
            if (url) {
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                [nc postNotificationName: kNotificationDiskImageAdded object: url];
            }
            break;

            // not disk images or don't use a path control.
        case kIndexPicture:
        case kIndexMidiIn:
        case kIndexMidiOut:
        case kIndexBitBanger:
        default: break;
    }
    
    [self rebuildArgs];
}

-(IBAction)textAction: (id)sender {
    [self rebuildArgs];
}
- (IBAction)midiAction:(id)sender {
    [self rebuildArgs];
}

-(IBAction)resetMedia:(id)sender {
    [self resetDiskImages];
}



-(void)magicRouteNotification: (NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    id path = [userInfo objectForKey: @"path"];
    
    if ([path isKindOfClass: [NSURL class]]) {
        [self smartRouteURL: path];
        return;
    }

    if ([path isKindOfClass: [NSString class]]) {
        NSURL *url = [NSURL fileURLWithPath: path];
        [self smartRouteURL: url];
        return;
    }
}
/*
 * given a file, add it to the media list.
 * TODO - how to handle if full or media type missing?
 */
-(BOOL)smartRouteURL: (NSURL *)url {
    
    if (!url) return NO;

    MediaType mt = ClassifyMediaFile(url);
    if (mt < 1) return NO; // unknown / error.
    
    unsigned ix = 0;
    switch(mt) {
        case MediaType_3_5: ix = kIndexFloppy35; break;
        case MediaType_5_25: ix = kIndexFloppy525; break;
        case MediaType_Cassette: ix = kIndexCassette; break;
        case MediaType_HardDisk: ix = kIndexHardDrive; break;
        case MediaType_CDROM: ix = kIndexCDROM; break;

        case MediaType_Picture: ix = kIndexPicture; break;
        case MediaType_MIDI: // ix = kIndexMidiIn; break;
        case MediaTypeError:
        case MediaTypeUnknown:
            return NO;
    }

    [_outlineView beginUpdates];
    // todo -- check root, insert if necessary?
    MediaCategory *cat = _data[ix];
    [cat addURL: url];
    [_outlineView endUpdates];

    [self rebuildArgs];
    return YES;
}

-(BOOL)smartRouteFile: (NSString *)file {
    return NO;
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

static NSString * BookmarkStrings[] = {
    @"flop_525", @"flop_35", @"hard", @"cdrm", @"cass", @"disk", @"bitb", @"midiin", @"midiout", @"pic"
};
static_assert(SIZEOF(BookmarkStrings) == CATEGORY_COUNT, "Missing item");

static int BookmarkIndex(NSString *str) {
    if (!str) return -1;
    for (int i = 0; i < SIZEOF(BookmarkStrings); ++i) {
        if ([str isEqualToString: BookmarkStrings[i]]) return i;
    }
    return -1;
}


-(BOOL)loadBookmark: (NSDictionary *)bookmark {

    // fragile - depends on order
    id media = [bookmark objectForKey: @"media"];
    
    if ([media isKindOfClass: [NSArray class]]) {
        unsigned ix = 0;
        for (NSArray *a in (NSArray *)media) {
            if (ix >= CATEGORY_COUNT) {
                NSLog(@"MediaViewController: too many categories.");
                break;
            }
            MediaCategory *cat = _data[ix];
            NSInteger count = [cat count];
            unsigned i = 0;
            for (NSString *path in a) {
                if (i >= count) {
                    NSLog(@"MediaViewController: too many files.");
                    break; //
                }
                MediaItem *item = [cat objectAtIndex: i++];
                if (![path length]) continue;

                if (ix == kIndexBitBanger || ix == kIndexMidiOut || ix == kIndexMidiIn) {
                    [item setString: path];
                } else {
                    NSURL *url = [NSURL fileURLWithPath: path];
                    [item setUrl: url];
                }
            }
            ++ix;
        }
        return YES;
    }
    if ([media isKindOfClass: [NSDictionary class]]) {
        
        for (NSString *key in (NSDictionary *)media) {
            NSInteger ix = BookmarkIndex(key);
            if (ix < 0) {
                NSLog(@"MediaViewController: unrecognized category: %@", key);
                continue;
            }
            MediaCategory *cat = _data[ix];
            NSInteger count = [cat count];
            NSArray *a = [(NSDictionary *)media objectForKey: key];
            unsigned i = 0;

            for (NSString *path in a) {
                if (i >= count) {
                    NSLog(@"MediaViewController: too many files.");
                    break; //
                }
                MediaItem *item = [cat objectAtIndex: i++];
                if (![path length]) continue;

                if (ix == kIndexBitBanger || ix == kIndexMidiOut || ix == kIndexMidiIn) {
                    [item setString: path];
                } else {
                    NSURL *url = [NSURL fileURLWithPath: path];
                    [item setUrl: url];
                }
            }
        }
        
        return YES;
    }
    return NO;
}

static void CompressArray(NSMutableArray *array) {
    
    for(;;) {
        NSString *s = [array lastObject];
        if (!s) return;
        if ([s length]) return;
        [array removeLastObject];
    }
}

-(BOOL)saveBookmark: (NSMutableDictionary *)bookmark {


    NSMutableDictionary *media = [NSMutableDictionary new];

    for (unsigned ix = 0; ix < CATEGORY_COUNT; ++ix) {
    
        MediaCategory *cat = _data[ix];
        NSInteger count = [cat validCount];
        if (!count) continue;
        
        NSMutableArray *array = [NSMutableArray new];
        for (NSInteger i = 0; i < count; ++i) {

            MediaItem *item = [cat objectAtIndex: i];
            NSString *s = [item argument];
            if (!s) s = @"";
            [array addObject: s];
        }

        CompressArray(array);
        
        if ([array count])
            [media setObject: array forKey: BookmarkStrings[ix]];
    }
    
    [bookmark setObject: media forKey: @"media"];
    
    return YES;
}

@end
