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
    
}


-(instancetype)init {
    
    if ((self = [super init])) {
        
        [self loadRecentDiskImages];
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
    
    [_tableView registerForDraggedTypes: @[NSPasteboardTypeURL]];
    
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

-(void)willTerminate: (NSNotification *)notification {
    // if dirty, write data....

    if (!_dirty) return;

    NSURL *sd = SupportDirectory();
    NSURL *url = [sd URLByAppendingPathComponent: @"RecentDiskImages.plist"];
    
    if (_content && url) {
        [_content writeToURL: url atomically: YES];
    }

    
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
    
    _dirty = YES;
    return YES;
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


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {

//    if ([rowIndexes count] > 1) return NO; // ?

    id objects = [_arrayController arrangedObjects];
    [pboard declareTypes: @[NSPasteboardTypeURL] owner: nil];
    // NSURLPboardType deprecated
    [rowIndexes enumerateIndexesUsingBlock: ^(NSUInteger index, BOOL *stop) {
        
        NSDictionary *d = [objects objectAtIndex: index];
        NSString *path = [d objectForKey: @"path"];

        NSURL *url = [NSURL fileURLWithPath: path];
        [url writeToPasteboard: pboard];
    }];
    // NSFilenamesPboardType -- old way of handling it ...

    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    
    return NSDragOperationCopy;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {


    NSPasteboard * pb = [info draggingPasteboard];
    NSURL *url = [NSURL URLFromPasteboard: pb];
    if (!url) return NO;
    
    return [self addFile: url];

}

@end
