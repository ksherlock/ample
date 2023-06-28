//
//  DiskImagesWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "DiskImagesWindowController.h"
#import "TableCellView.h"
#import "Ample.h"
#import "DiskImage.h"

#import "BookmarkManager.h"

@interface DiskImagesWindowController ()
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;

@end

@implementation DiskImagesWindowController {
    NSSet *_extensions;
}

+(instancetype)sharedInstance {
    static DiskImagesWindowController *me;
    if (!me) {
        me = [self new];
    }
    return me;
}

+ (void)restoreWindowWithIdentifier:(NSUserInterfaceItemIdentifier)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
    NSLog(@"restore disk images window");
    NSWindowController *controller = [self sharedInstance];
    NSWindow *w = [controller window];
    [w restoreStateWithCoder: state];
    completionHandler(w, nil);
}

-(instancetype)init {
    
    if ((self = [super init])) {
        
        //[self loadRecentDiskImages];
        
        _extensions = [NSSet setWithObjects:
            @"2img", @"2mg", @"chd", @"dc", @"do", @"dsk", @"hd", @"hdv", @"image", @"nib", @"po", @"wav", @"woz", @"iso", @"raw",
            // st, etc.
            @"mfm",   @"st", @"msa", @"stx", @"ipf",
            //
            @"rom", @"bin",
            // not supported/relevant.
            // @"mfi", @"dfi", @"hfe",  @"d77"  @"d88", @"1dd", @"cqm", @"cqi", @"td0", @"imd", 
            nil
        ];
    }
    return self;
}

-(NSString *)windowNibName {
    return @"DiskImages";
}

- (void)windowDidLoad {

    [super windowDidLoad];
    NSWindow *window = [self window];
    [window setRestorable: YES];
    [window setRestorationClass: [self class]];

    if (@available(macOS 10.13, *)) {
        [_tableView registerForDraggedTypes: @[NSPasteboardTypeFileURL]];
    } else {
        [_tableView registerForDraggedTypes: @[ (NSString *)kUTTypeFileURL ]];
    }
    [_tableView setDraggingSourceOperationMask: NSDragOperationCopy forLocal: NO]; // enable drag/drop to othr apps.

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];
    [_arrayController setSortDescriptors: @[ s ]];
}

#if 0
-(void)loadRecentDiskImages {
//    NSError *error;

    NSURL *sd = SupportDirectory();
    NSURL *url = [sd URLByAppendingPathComponent: @"RecentDiskImages.plist"];

    NSData *data = [NSData dataWithContentsOfURL: url];
    if (data) {
        _content = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error: nil];

    }
    if (!_content)
        _content = [NSMutableArray new];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self selector: @selector(diskImageAdded:) name: kNotificationDiskImageAdded object: nil];
    
    [nc addObserver: self selector: @selector(willTerminate:) name: NSApplicationWillTerminateNotification object: nil];
}

-(void)timerCallback: (NSTimer *)timer {
    _timer = nil;
    [self saveFile];
}
#endif

-(void)diskImageAdded: (NSNotification *)notification {
    
    NSURL *url = [notification object];
    if (!url) return;
    
    //[self addFile: url];
}
#if 0
-(void)markDirty {
    _dirty = YES;
    if (_timer) [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval: 5 * 60 target: self selector: @selector(timerCallback:) userInfo: nil repeats: NO];
#if 0
    // 10.12+
    _timer = [NSTimer scheduledTimerWithTimeInterval: 5 * 60 repeats: NO block: ^(NSTimer *t) {
        
        self->_timer = nil;
        [self saveFile];
    }];
#endif
}


-(void)saveFile {

    [_timer invalidate];
    _timer = nil;

    NSURL *sd = SupportDirectory();
    NSURL *url = [sd URLByAppendingPathComponent: @"RecentDiskImages.plist"];
    
    if (_content && url) {
        [_content writeToURL: url atomically: YES];
    }
    _dirty = NO;

}

-(void)willTerminate: (NSNotification *)notification {
    // if dirty, write data....

    if (!_dirty) return;

    [self saveFile];
    
}
#endif



#if 0
-(BOOL)addFile: (NSObject *)pathOrURL {
    
    NSString *path = nil;
    NSURL *url = nil;
    if ([pathOrURL isKindOfClass: [NSString class]]) {
        path = (NSString *)pathOrURL;
    } else if ([pathOrURL isKindOfClass: [NSURL class]]){
        url = (NSURL *)pathOrURL;

        path = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
    }
    if (!path) return NO;

    // todo -- check if file is in the list already...

    BOOL found = NO;
    // should really compare the volume id / ino I suppose.
    for (NSMutableDictionary *d in _content) {
        NSString *s = [d objectForKey: @"path"];
        if ([path compare: s] == NSOrderedSame) {
            found = YES;
            [d setObject: [NSDate new] forKey: @"date"];
            [self markDirty];
            break;
        }
    }
    if (found) return NO;
    
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;

    NSDictionary *attr = [fm attributesOfItemAtPath: path error: &error];
    if (error) {
        NSLog(@"%@ : %@", path, error);
        return NO;
    }
    
    
    NSNumber *size = [attr objectForKey: NSFileSize];
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              path, @"path",
                              size, @"size",
                              [NSDate new], @"date",
                              nil];
    
#if 0
    @synchronized (self) {
        if (_arrayController)
            [_arrayController addObject: d];
        else
            [_content addObject: d];
    }
#endif
    [self markDirty];
    return YES;
}

#endif
-(DiskImage *)clickedItem {

    NSArray *array = [_arrayController arrangedObjects];
    NSInteger row = [_tableView clickedRow];
    if (row < 0 || row >= [array count]) return nil;
    return [array objectAtIndex: row];
}
#pragma mark - IBActions

- (IBAction)filter:(id)sender {
    NSString *text = [sender stringValue];
    NSPredicate *p = nil;
    if ([text length]) {
        p = [NSPredicate predicateWithFormat: @"name CONTAINS[cd] %@",text];
    }

    [_arrayController setFilterPredicate: p];
}

- (IBAction)showInFinder:(id)sender {
    
    DiskImage *item = [self clickedItem];
    if (!item) return;
    NSString *path = [item path];

    NSURL *url = [NSURL fileURLWithPath: path];
    if (!url) return;

    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws activateFileViewerSelectingURLs: @[url]];
}

- (IBAction)eject:(id)sender {

    DiskImage *item = [self clickedItem];
    if (!item) return;
    
    [_arrayController removeObject: item];
}

-(IBAction)doubleClick: (id)sender {
    DiskImage *d = [self clickedItem];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    NSDictionary *userInfo = @{ @"path": [d path] };
    [nc postNotificationName: kNotificationDiskImageMagicRoute object: nil userInfo: userInfo];
}

@end

@implementation DiskImagesWindowController (TableView)


-(id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    
    id objects = [_arrayController arrangedObjects];
    
    DiskImage *d = [objects objectAtIndex: row];
    if (!d) return nil;
    NSString *path = [d path];
    
    NSURL *url = [NSURL fileURLWithPath: path];
    return url;
    
#if 0
    NSPasteboardItem *item = [NSPasteboardItem new];
    [item setString: [url absoluteString] forType: NSPasteboardTypeFileURL]; // FileURL
    [item setString: path forType: NSPasteboardTypeString]; // for Terminal.app

    return item;
#endif
}



-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {

    if ([info draggingSource] == _tableView) return NSDragOperationNone;

    // option key will ignore all filetype restrictions.
    if ([NSEvent modifierFlags] & NSEventModifierFlagOption) return NSDragOperationCopy;

    // this only checks the first dragged item...
    NSPasteboard * pb = [info draggingPasteboard];
    NSURL *url = [NSURL URLFromPasteboard: pb];
    
    NSString *ext = [url pathExtension];
    ext = [ext lowercaseString];
    if ([_extensions containsObject: ext])
        return NSDragOperationCopy;
    
    return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {

    BookmarkManager *bm = [BookmarkManager sharedManager];
    
    if ([info draggingSource] == _tableView) return NO;

    NSPasteboard * pb = [info draggingPasteboard];
    
    BOOL ok = NO;
    for (NSPasteboardItem *item in [pb pasteboardItems]) {
        
        // need to convert from a string to a url back to a file in case it's a file id url?
        NSString *s;
        if (@available(macOS 10.13, *)) {
            s = [item stringForType: NSPasteboardTypeFileURL];
        } else {
            // El Capitan still has kUTTypeFileURL aka public.file-url but doesn't have NSPasteboardTypeFileURL
            s = [item stringForType: (NSString *)kUTTypeFileURL];
        }
        if (!s) continue;
        NSURL *url = [NSURL URLWithString: s];
        if (!url) continue;
        
        ok |= [bm addDiskImage: url];
        //ok |= [self addFile: url];
    }
    return ok;
}

@end
