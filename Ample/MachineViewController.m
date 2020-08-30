//
//  MachineViewController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "MachineViewController.h"

@interface MachineViewController()

@property NSArray *data;

@end

@implementation MachineViewController


-(void)awakeFromNib {

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource: @"models" ofType: @"plist"];
    _data = [NSArray arrayWithContentsOfFile: path];

    
    /* My Copy of XCode/Interface Builder barfs on NSBrowser. */
    
    NSBrowser *browser;
    NSRect frame = NSMakeRect(0, 0, 718, 200);

    browser = [[NSBrowser alloc] initWithFrame: frame];
    
    [browser setMaxVisibleColumns: 2];
    //[browser setTakesTitleFromPreviousColumn: YES];
    //[browser setTitled: NO];
    [browser setAllowsEmptySelection: NO];
    [browser setDelegate: self];
    [browser setAction: @selector(clickAction:)];
    
    [self setView: browser];
}

-(IBAction)clickAction:(id)sender {
    
    NSDictionary *item = [self itemForBrowser: sender];
    [self setMachine: [item objectForKey: @"value"]];
}

#pragma mark NSBrowser

-(NSDictionary *)itemForBrowser: (NSBrowser *)browser {
    
    NSIndexPath *path = [browser selectionIndexPath];
    
    NSArray *data = _data;
    NSDictionary *item = nil;
    
    NSUInteger l = [path length];
    for (NSUInteger i = 0; i < l; ++i) {
        NSUInteger ix = [path indexAtPosition: i];
        if (ix > [data count]) return nil;
        item = [data objectAtIndex: ix];
        data = [item objectForKey: @"children"];
    }
    
    return item;
}
-(NSArray *)itemsForBrowser: (NSBrowser *)browser column: (NSInteger) column {

    NSArray *data = _data;
    for (unsigned i = 0; i < column; ++i) {
        NSInteger ix = [browser selectedRowInColumn: i];
        if (ix < 0) return 0;

        NSDictionary *item = [data objectAtIndex: ix];
        data = [item objectForKey: @"children"];
        if (!data) return 0;
    }
    return data;
    
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column {
    NSArray *data = [self itemsForBrowser: sender column: column];
    if (!data || row >= [data count]) return;

    NSDictionary *item = [data objectAtIndex: row];
    
    NSBrowserCell *bc = (NSBrowserCell *)cell;
    
    [bc setStringValue: [item objectForKey: @"description"]];
    [bc setLeaf: ![item objectForKey: @"children"]];
}


- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(NSInteger)column {
    return column == 0 ? @"Model" : @"";
}

#if 0
- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    return nil;
}
#endif

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column {
    
    NSArray *data = [self itemsForBrowser: sender column: column];
    return [data count];
}


@end
