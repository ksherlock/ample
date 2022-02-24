//
//  BookmarkWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 2/6/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//

#import "BookmarkWindowController.h"
#import "BookmarkManager.h"
#import "Bookmark.h"
#import "Ample.h"



@interface BookmarkWindowController ()
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet BookmarkManager *bookmarkManager;

@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation BookmarkWindowController


+(instancetype)sharedInstance {
    static BookmarkWindowController *me = nil;
    if (!me) {
        me = [self new];
    }
    return me;
}

-(NSString *)windowNibName {
    return @"BookmarkWindow";
}


- (void)windowDidLoad {
    [super windowDidLoad];

    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];

    [_arrayController setSortDescriptors: @[s]];

}

-(BOOL)windowShouldClose: (NSWindow *)sender {

    NSManagedObjectContext *moc = [_arrayController managedObjectContext];
    NSError *error;
    
    if (![_arrayController commitEditing]) return NO;

    if ([moc save: &error]) return YES;
    NSLog(@"%@", error);
   
#if 0
    NSDictionary *dict = [error userInfo];
    NSArray *array = [dict objectForKey: @"conflictList"];
    for (NSConstraintConflict *c in array) {
        
        NSArray * arr = [c conflictingObjects];
        for (NSManagedObject *o in arr) {
 
        }
    }
#endif
    return YES;

    //[self presentError: error];
    //return NO;
}

-(void)keyDown:(NSEvent *)event {
    /* Carbon/Events.h */
    enum {
        kVK_Delete                    = 0x33,
        kVK_ForwardDelete             = 0x75,

    };
    unsigned short keyCode = [event keyCode];

    if (keyCode == kVK_Delete || keyCode == kVK_ForwardDelete) {
        
        // arraycontroller selected object / selected index doesn't work right.
        
        NSInteger row = [_tableView selectedRow];
        if (row >= 0)
            [_arrayController removeObjectAtArrangedObjectIndex: row];
        
    }
}

-(Bookmark *)clickedItem {

    NSArray *array = [_arrayController arrangedObjects];
    NSInteger row = [_tableView clickedRow];
    if (row < 0 || row >= [array count]) return nil;
    return [array objectAtIndex: row];
}

-(IBAction)doubleClick:(id)sender {
    
    Bookmark *b = [self clickedItem];
    if (!b) return;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc postNotificationName: kNotificationBookmarkMagicRoute object: b];
}

-(IBAction)toggleDefault:(id)sender {
    NSLog(@"%@", sender);


}

-(IBAction)setDefault:(id)sender {

    Bookmark *b = [self clickedItem];
    if (!b) return;
    
    [_bookmarkManager setAutomatic: b];
}

-(IBAction)clearDefault:(id)sender {
    
    Bookmark *b = [self clickedItem];
    if (!b) return;

    [b setAutomatic: NO];
}


-(IBAction)deleteBookmark:(id)sender {

    //Bookmark *b = [self clickedItem];
    //if (!b) return;

    NSInteger row = [_tableView clickedRow];
    if (row >= 0)
        [_arrayController removeObjectAtArrangedObjectIndex: row];
}

@end

@implementation BookmarkWindowController (Menu)

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    
    Bookmark *b = [self clickedItem];
    
    if (!b) return NO;
    SEL action = [menuItem action];
    
    if (action == @selector(clearDefault:)) {
        return [b automatic];
    }

    if (action == @selector(setDefault:)) {
        return ![b automatic];
    }


    return YES;
}

@end
