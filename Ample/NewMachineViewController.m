//
//  NewMachineViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 6/8/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import "NewMachineViewController.h"

@interface NewMachineViewController () {

    NSArray *_data;
}

@property (weak) IBOutlet NSOutlineView *outlineView;

@end

@implementation NewMachineViewController

-(void)awakeFromNib {
    
    static unsigned first = 0;
    
    if (first) return;
    first++;

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource: @"models" ofType: @"plist"];
    _data = [NSArray arrayWithContentsOfFile: path];

}

-(void)viewDidLoad {
    [super viewDidLoad];

    //[_outlineView reloadData];
    //[_outlineView setAutosaveExpandedItems: YES];
    //[_outlineView expandItem: nil expandChildren: YES];
}

#pragma mark - IBActions
- (IBAction)clickAction:(id)sender {
    
    NSInteger row = [_outlineView clickedRow];
    if (row < 0) return;
    NSDictionary *item = [_outlineView itemAtRow: row];
    if (!item) return;

    NSString *value = [item objectForKey: @"value"];
    NSArray *children = [item objectForKey: @"children"];
    
    if (value) {
        [self setMachine: value];
    } else if (children) {
        id ap = [_outlineView animator];
        [_outlineView isItemExpanded: item] ? [ap collapseItem: item] : [ap expandItem: item];
    }


}

-(void)reset {
    
    [_outlineView deselectAll: nil];
    [self setMachine: nil];
}
@end


@implementation NewMachineViewController (Table)

#if 0
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    return NO;
}
#endif

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    // disclosure triangle.
    if (!item) return YES;
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    return [children count] > 0;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (!item) return YES;
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    return [children count] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    
#if 0
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    return [children count] > 0;
#else
    return NO;
#endif
}


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {

#if 0
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    if ([children count]) {
        return [outlineView makeViewWithIdentifier: @"HeaderCell" owner: self];
    }
#endif
    NSTableCellView *v = [outlineView makeViewWithIdentifier: @"DataCell" owner: self];
    //[v setObjectValue: item];
    return v;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) return [_data count];
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    return [children count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (item == nil) {
        return [_data objectAtIndex: index];
    }
    NSArray *children = [(NSDictionary *)item objectForKey: @"children"];
    return [children objectAtIndex: index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if (!item) return NO;
    return [(NSDictionary *)item objectForKey: @"value"] != nil;
}


// saving/restoring expanded items
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
    
    return [item objectForKey: @"description"];
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
    
    if ([object isKindOfClass: [NSString class]]) {
        
        for(NSDictionary *d in _data) {
            if ([(NSString *)object isEqualToString: [d objectForKey: @"description"]])
                return d;
        }
        
    }
    return nil;
    //return object;
}


@end


@implementation NewMachineViewController (Bookmark)


- (void)didLoadBookmark:(NSDictionary *)bookmark {
}

- (BOOL)loadBookmark:(NSDictionary *)bookmark {
    NSString *machine = [bookmark objectForKey: @"machine"];

    

    //NSInteger row = [_outlineView selectedRow];
    if (!machine) {
        [self setMachine: nil];
        [_outlineView deselectAll: nil];
        return NO;
    }

    for (NSDictionary *parent in _data) {
        NSArray *children = [parent objectForKey: @"children"];
        
        for (NSDictionary *child in children) {
            if ([machine isEqualToString: [child objectForKey: @"value"]]) {
                
                id ap = [_outlineView animator];
                [ap expandItem: parent];
                NSInteger row = [_outlineView rowForItem: child];
                if (row >= 0) {
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex: row];
                    [_outlineView selectRowIndexes: set byExtendingSelection: NO];
                    [_outlineView scrollRowToVisible: row];
                    return YES;
                }
                return NO;
            }
        }

        // could also match parent.
        if ([machine isEqualToString: [parent objectForKey: @"value"]]) {
            NSInteger row = [_outlineView rowForItem: parent];
            if (row >= 0) {
                NSIndexSet *set = [NSIndexSet indexSetWithIndex: row];
                [_outlineView selectRowIndexes: set byExtendingSelection: NO];
                [_outlineView scrollRowToVisible: row];
                return YES;
            }
            return NO;
        }
    }
    
    return NO;
}

- (BOOL)saveBookmark:(NSMutableDictionary *)bookmark {
    // machine saved in parent.
    return YES;
}

- (void)willLoadBookmark:(NSDictionary *)bookmark {

}

@end
