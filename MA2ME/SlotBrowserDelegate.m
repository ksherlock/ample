//
//  SlotBrowserDelegate.m
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "SlotBrowserDelegate.h"

@interface SlotBrowserDelegate () {

    NSString *_model;
    NSMutableArray *_data;
}
@end

@implementation SlotBrowserDelegate

-(void)awakeFromNib {
    _data = [NSMutableArray new];
}

@synthesize model = _model;

static NSString *Mame[] = {
    @"-sl0", @"-sl1", @"-sl2", @"-sl3",
    @"-sl4", @"-sl5", @"-sl6", @"-sl7",
    @"-sl8", @"-exp", @"-aux",
    @"-gameio", @"-printer", @"-modem", @"-rs232"
};

static NSString *Keys[] = {
    @"slot0", @"slot1", @"slot2", @"slot3",
    @"slot4", @"slot5", @"slot6", @"slot7",
    @"slot8", @"exp", @"aux",
    @"gameio", @"printer", @"modem", @"rs232"
};

static NSString *Names[] = {
    @"Slot 0", @"Slot 1", @"Slot 2", @"Slot 3",
    @"Slot 4", @"Slot 5", @"Slot 6", @"Slot 7",
    @"Slot 8", @"Expansion", @"Auxiliary",
    @"Game I/O", @"Printer", @"Modem", @"RS232"
};


-(void)setModel:(NSString *)model {

    
    if (_model == model) return;
    if ([_model isEqualToString: model]) return;
    _model = model;
    
    [_data removeAllObjects];

    if (!model) return;
    
    NSBundle *bundle = [NSBundle mainBundle];

    NSDictionary *none = @{ @"Name": @"None", @"Mame": @"" };
    
    for (unsigned i = 0; i < sizeof(Keys)/sizeof(Keys[0]); ++i) {
        NSString *key = Keys[i];

        NSString *path = [bundle pathForResource: key ofType: @"plist" inDirectory: model];
        if (!path) {
            [self setValue: nil forKey: key];
            continue;
        }
        NSMutableArray *data = [NSMutableArray arrayWithContentsOfFile: path];

        if (![data count]) {
            [self setValue: nil forKey: key];
            continue;
        }
        
        [data insertObject: none atIndex: 0];
        
        NSString *value = [self valueForKey: key];
        if (value) {
            BOOL found = NO;
            for (NSDictionary *item in data) {
                if ([value isEqualToString: [item objectForKey: @"Mame"]]) {
                    found = YES;
                    break;
                }
            }
            if (!found) [self setValue: nil forKey: key];
        }
        
        NSDictionary *item = @{
            @"Children": data,
            @"Name": Names[i],
            @"Mame": key
        };
        [_data addObject: item];
    }
    // needs to call [NSBrowser reloadColumn0];
    [_browser loadColumnZero];
}

#if 0
-(id)rootItemForBrowser:(NSBrowser *)browser {
    return _data;
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {

    if (!item) return YES;
    if (item == _data) return NO;

    return ![(NSDictionary *)item objectForKey: @"Children"];
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {

    if (!item) return nil;
    if (item == _data) return [item objectAtIndex: index];

    NSArray *data = [item objectForKey: @"Children"];
    return [data objectAtIndex: index];
    
}


-(id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    if (item == _data) return @"Root";
    return [item objectForKey: @"Name"];
}


- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    NSArray *data = item == _data ? item : [item objectForKey: @"Children"];
    return [data count];
}
#endif

-(void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column {
    [(NSBrowserCell *)cell set];
    [(NSBrowserCell *)cell setLeaf: YES];
    [(NSBrowserCell *)cell setStringValue: @"Hello"];
}


-(NSArray *)args {
    NSMutableArray *array = [NSMutableArray new];
    
    for (unsigned i = 0; i < sizeof(Keys)/sizeof(Keys[0]); ++i) {
        NSString *key = Keys[i];
    
        NSString *value = [self valueForKey: key];
        if (!value || ![value length]) continue;
        [array addObject: Mame[i]];
        [array addObject: value];
    }
    return array;
}

@end
