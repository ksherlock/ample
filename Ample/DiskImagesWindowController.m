//
//  DiskImagesWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "DiskImagesWindowController.h"
#import "TableCellView.h"

@interface DiskImagesWindowController ()
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property NSMutableArray *content;
@end

@implementation DiskImagesWindowController {
    //NSArray *_data;
    
}

-(NSString *)windowNibName {
    return @"DiskImages";
}

- (void)windowDidLoad {
    //_data = [NSMutableArray new];
    [self setContent:
        [NSMutableArray arrayWithObject:
         [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"/path/to/a/file.2mg", @"path",
            @(12345), @"size",
            nil]
     ]];
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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


@end
