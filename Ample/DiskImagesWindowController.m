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

@interface DiskImagesWindowController ()
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) NSMutableArray *content;

@end

@implementation DiskImagesWindowController {
    BOOL _dirty;
    NSSet *_extensions;
    NSTimer *_timer;
    
}


-(instancetype)init {
    
    if ((self = [super init])) {
        
        [self loadRecentDiskImages];
        
        _extensions = [NSSet setWithObjects:
            @"2img", @"2mg", @"chd", @"dc", @"do", @"dsk", @"hd", @"hdv", @"image", @"nib", @"po", @"wav", @"woz", @"iso", nil
        ];
    }
    return self;
}

-(NSString *)windowNibName {
    return @"DiskImages";
}

- (void)windowDidLoad {

    if (!_content)
        [self setContent: [NSMutableArray new]];
    
    [super windowDidLoad];
    
    [_tableView registerForDraggedTypes: @[NSPasteboardTypeFileURL]];
    [_tableView setDraggingSourceOperationMask: NSDragOperationCopy forLocal: NO]; // enable drag/drop to othr apps.

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

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
    
    [nc addObserver: self selector: @selector(diskImageAdded:) name: @"DiskImageAdded" object: nil];
    
    [nc addObserver: self selector: @selector(willTerminate:) name: NSApplicationWillTerminateNotification object: nil];
}

-(void)diskImageAdded: (NSNotification *)notification {
    
    NSURL *url = [notification object];
    if (!url) return;
    
    [self addFile: url];
}
-(void)markDirty {
    _dirty = YES;
    if (_timer) [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval: 5 * 60 repeats: NO block: ^(NSTimer *t) {
        
        self->_timer = nil;
        [self saveFile];
    }];
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
    
    @synchronized (self) {
        if (_arrayController)
            [_arrayController addObject: d];
        else
            [_content addObject: d];
    }
    [self markDirty];
    return YES;
}


-(NSMutableDictionary *)clickedItem {

    NSInteger row = [_tableView clickedRow];
    if (row < 0) return nil;

    NSTableCellView *v = [_tableView viewAtColumn: 0 row: row makeIfNecessary: NO];
    return [v objectValue];
}
#pragma mark - IBActions

- (IBAction)showInFinder:(id)sender {
    
    NSMutableDictionary *item = [self clickedItem];
    if (!item) return;
    NSString *path = [item objectForKey: @"path"];

    NSURL *url = [NSURL fileURLWithPath: path];
    if (!url) return;

    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws activateFileViewerSelectingURLs: @[url]];
}

- (IBAction)eject:(id)sender {

    NSMutableDictionary *item = [self clickedItem];
    if (!item) return;
    
    @synchronized (self) {
        
        if (_arrayController) {
            [_arrayController removeObject: item];
        } else {
            [_content removeObject: item];
        }
        [self markDirty];
    }

}

@end

@implementation DiskImagesWindowController (TableView)

#if 0
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 5; //[_data count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *v = [tableView makeViewWithIdentifier: @"PathCell" owner: self];
    
    return v;
}
#endif


-(id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    
    id objects = [_arrayController arrangedObjects];
    
    NSDictionary *d = [objects objectAtIndex: row];
  
    NSString *path = [d objectForKey: @"path"];
    
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

    if ([info draggingSource] == _tableView) return NO;

    NSPasteboard * pb = [info draggingPasteboard];
    
    BOOL ok = NO;
    for (NSPasteboardItem *item in [pb pasteboardItems]) {
        
        // need to convert from a string to a url back to a file in case it's a file id url?
        NSString *s = [item stringForType: NSPasteboardTypeFileURL];
        if (!s) continue;
        NSURL *url = [NSURL URLWithString: s];
        if (!url) continue;
        
        ok |= [self addFile: url];
    }
    return ok;
}

@end
