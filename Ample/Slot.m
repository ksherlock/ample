//
//  Slot.m
//  Ample
//
//  Created by Kelvin Sherlock on 3/6/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Slot.h"


static NSArray *DeepCopyArray(NSArray *src) {
    if (!src) return nil;
    return [[NSArray alloc] initWithArray: src copyItems: YES];
}

@interface Slot () {
    NSArray<SlotOption *> *_options;
    //NSArray<NSMenuItem *> *_menuItems;
}

-(SlotOption *)selectedItem;

-(void)setKeyPath;
-(void)setKeyPath: (NSString *)path;
//-(NSArray *)buildArgs: (NSMutableArray *)args prefix: (NSString *)prefix;
//-(void)buildMedia: (MediaBuilder *)builder;
//-(NSArray *)buildSerial: (NSMutableArray *)array;
@end

@interface SlotOption() {
    NSArray<Slot *> *_children;
    //NSDictionary *_media;
    Media _media;
    NSString *_keyPath;
    NSString *_devName;
    BOOL _default;
}

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

-(NSMenuItem *)menuItem;

-(void)reset;

-(void)setKeyPath: (NSString *)path;
-(void)buildArgs: (NSMutableArray *)args;
-(void)buildMedia: (Media *)media;
-(void)buildSerial: (NSMutableArray *)array;

-(BOOL)loadDeviceSlots: (NSDictionary *)devices;

@end

@implementation Slot


-(void)reset {
    [self setSelectedIndex: _defaultIndex >= 0 ? _defaultIndex : 0];
    for (SlotOption *s in _options) {
        [s reset];
    }
}

-(void)selectValue: (NSString *)value {

    if (value) {
        NSInteger index = 0;
        for (SlotOption *item in _options) {
            if ([[item value] isEqualToString: value]) {
                [self setSelectedIndex: index];
                return;
            }
            ++index;
        }
    }
    //[self setSelectedIndex: _defaultIndex >= 0 ? _defaultIndex : 0];
}

-(SlotOption *)selectedItem {
    if (_selectedIndex < 0) return nil;
    return [_options objectAtIndex: _selectedIndex];
}

-(NSArray *)args {
    if (_selectedIndex < 0) return nil;
    NSMutableArray *rv = [NSMutableArray new];
    SlotOption *option = [_options objectAtIndex: _selectedIndex];
    
    [option buildArgs: rv];
    return rv;
}

-(NSArray *)serialize {
    if (_selectedIndex < 0) return nil;
    
    NSMutableArray *array = [NSMutableArray new];
    SlotOption *option = [_options objectAtIndex: _selectedIndex];
    [option buildSerial: array];
    return array;
}

-(Media)selectedMedia {

    if (_selectedIndex < 0) return EmptyMedia;

    Media media = { 0 };
    SlotOption *option = [_options objectAtIndex: _selectedIndex];

    [option buildMedia: &media];
    return media;

}


-(id)copyWithZone:(NSZone *)zone {
    
    Slot *child = [Slot new];
    child->_index = _index;
    child->_defaultIndex = _defaultIndex;
    child->_selectedIndex = _selectedIndex;
    child->_name = [_name copyWithZone: zone];
    child->_title = [_title copyWithZone: zone];
    child->_options = DeepCopyArray(_options);
    
    #if 0
    // menu could still be in use by an off-screen pop up button, so it can't be cached.
    child->_menuItems = DeepCopyArray(_menuItems);
    // update represented object.
    NSInteger index = 0;
    for (NSMenuItem *item in child->_menuItems) {
        [item setRepresentedObject: child->_options[index]];
        ++index;
    }
    #endif
    return child;
}


-(void)setKeyPath {
    if (![_name length]) return;
    for (SlotOption *o in _options)
        [o setKeyPath: _name];
}
-(void)setKeyPath: (NSString *)path {
    
    NSString *p = [path stringByAppendingString: _name];
    for (SlotOption *o in _options) {
        [o setKeyPath: p];
    }
}



-(instancetype)initWithName: (NSString *)name title: (NSString *)title data: (NSArray *)data {
    
    _name = [name copy];
    _title = [title copy];
    _selectedIndex = -1;
    _defaultIndex = -1;
    _index = -1;
    
    NSMutableArray *options = [NSMutableArray arrayWithCapacity: [data count]];
    //NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity: [data count]];

    NSInteger index = 0;
    for (NSDictionary *d in data) {
        SlotOption *o = [[SlotOption alloc] initWithDictionary: d];
        if ([o isDefault]) {
            _defaultIndex = index;
        }
        ++index;
        [options addObject: o];
    }
    _options = options;
    //_menuItems = menuItems;
    
    _selectedIndex = _defaultIndex;
    if (_selectedIndex < 0) _selectedIndex = 0;
    
    return self;
}

-(NSArray *)menuItems {
    //if (_menuItems) return _menuItems;

    NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity: [_options count]];
    for (SlotOption *o in _options) {
        [menuItems addObject: [o menuItem]];
    }
    //_menuItems = tmp;
    return menuItems;
}

-(void)loadDeviceSlots: (NSDictionary *)devices {
    for (SlotOption *s in _options) {
        [s loadDeviceSlots: devices];
    }
}

-(void)prepareView: (SlotTableCellView *)view {
    
    // can't cache the menu items since they
    // may still be in use.
    
    NSPopUpButton *button = [view menuButton];
    NSTextField *text = [view textField];
    
    [text setObjectValue: _title];
    [button unbind: @"selectedIndex"];
    NSMenu *menu = [button menu];
    NSArray *menuItems = [self menuItems];

    [menu setItemArray: menuItems];
    [button bind: @"selectedIndex" toObject: self withKeyPath: @"selectedIndex" options: nil];
    [button setTag: _index];
}


@end


@implementation SlotOption

@synthesize  isDefault = _default;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary {
    
    _default = [(NSNumber *)[dictionary objectForKey: @"default"] boolValue];
    _disabled = [(NSNumber *)[dictionary objectForKey: @"disabled"] boolValue];
    _value = [dictionary objectForKey: @"value"];
    _devName = [dictionary objectForKey: @"devName"];
    _title = [dictionary objectForKey: @"description"];
    _media = MediaFromDictionary([dictionary objectForKey: @"media"]);
    //_media = [dictionary objectForKey: @"media"];
    return self;
}

-(void)reset {
    for (Slot *s in _children) {
        [s reset];
    }
}


-(NSMenuItem *)menuItem {
    NSMenuItem *item;
    extern NSAttributedString *ItalicMenuString(NSString *);
    
    item = [[NSMenuItem alloc] initWithTitle: _title action: NULL keyEquivalent: @""];
    if (_disabled) {
        [item setEnabled: NO];
    }
    if (_default) {
        [item setAttributedTitle: ItalicMenuString(_title)];
    }
    [item setRepresentedObject: self];
    return item;
}

-(id)copyWithZone:(NSZone *)zone {

    SlotOption *child = [SlotOption new];
    
    child->_default = _default;
    child->_disabled = _disabled;
    child->_media = _media;
    child->_value = [_value copyWithZone: zone];
    child->_devName = [_devName copyWithZone: zone];
    child->_title = [_title copyWithZone: zone];
    //child->_media = [_media copyWithZone: zone];
    child->_keyPath = [_keyPath copyWithZone: zone];

    child->_children = DeepCopyArray(_children);
    
    return child;
}



-(void)buildArgs: (NSMutableArray *)args {
    
    if (!_default) {
        [args addObject: _keyPath];
        [args addObject: _value];
    }
    for (Slot *s in _children) {
        [[s selectedItem] buildArgs: args];
    }
}

-(void)buildMedia: (Media *)media {
    
#undef _
#define _(name) media->name += _media.name

    _(cass);
    _(cdrom);
    _(hard);
    _(floppy_3_5);
    _(floppy_5_25);
    _(pseudo_disk);
#undef _
        
    for (Slot *s in _children) {
        [[s selectedItem] buildMedia: media];
    }
}


-(void)buildSerial: (NSMutableArray *)array {

    if (!_default)
        [array addObject: _keyPath];

    for (Slot *s in _children)
        [[s selectedItem] buildSerial: array];

}


// propogate
-(void)setKeyPath: (NSString *)path {
    
    _keyPath = path;
    if (!_children) return;
    NSString *p = [path stringByAppendingFormat: @":%@", _value];
    
    for (Slot *s in _children) {
        [s setKeyPath: p];
    }
}


-(BOOL)loadDeviceSlots: (NSDictionary *)devices {
    NSArray *o = [devices objectForKey: _devName];
    if (!o) return NO;
    _children = DeepCopyArray(o);
    return YES;
}

@end


@implementation SlotTableCellView

@end


NSArray *BuildSlots(NSString *name, NSDictionary *data) {

    static NSCache *cache = nil;
    
    typedef struct SlotInfo {
        NSString *key;
        NSString *flag;
        NSString *title;
    } SlotInfo;

    static SlotInfo Slots[] = {
        { @"ram",        @"-ramsize",    @"RAM:"  },
        { @"sl0",        @"-sl0",        @"Slot 0:" },
        { @"sl1",        @"-sl1",        @"Slot 1:" },
        { @"sl2",        @"-sl2",        @"Slot 2:" },
        { @"sl3",        @"-sl3",        @"Slot 3:" },
        { @"sl4",        @"-sl4",        @"Slot 4:" },
        { @"sl5",        @"-sl5",        @"Slot 5:" },
        { @"sl6",        @"-sl6",        @"Slot 6:" },
        { @"sl7",        @"-sl7",        @"Slot 7:" },
        { @"exp",        @"-exp",        @"Expansion:" },
        { @"aux",        @"-aux",        @"Auxiliary:" },
        { @"rs232",      @"-rs232",      @"RS232:" },
        { @"gameio",     @"-gameio",     @"Game I/O:" },
        { @"modem",      @"-modem",      @"Modem:" },
        { @"printer",    @"-printer",    @"Printer:" },

        // nubus mac
        { @"nb9",        @"-nb9",        @"Slot 9:" },
        { @"nba",        @"-nba",        @"Slot A:" },
        { @"nbb",        @"-nbb",        @"Slot B:" },
        { @"nbc",        @"-nbc",        @"Slot C:" },
        { @"nbd",        @"-nbd",        @"Slot D:" },
        { @"nbe",        @"-nbe",        @"Slot E:" },
    };

    
    #define SIZEOF(x) (sizeof(x) / sizeof(x[0]))
    
    if (!cache) {
        cache = [NSCache new];
    }
    
    extern NSString *InternString(NSString *);
    name = InternString(name);
    NSArray *x = [cache objectForKey: name];
    if (x) {
        return x;
    }
    
    NSMutableArray *rv = [NSMutableArray new];
    for (unsigned i = 0, index = 1; i < 21; ++i, index <<= 1) {
        NSArray *tmp = [data objectForKey: Slots[i].key];
        if (!tmp) continue;

        Slot *s = [[Slot alloc] initWithName: Slots[i].flag title: Slots[i].title data: tmp];
        [s setIndex: i];
        
        [s setKeyPath];
        [rv addObject: s];
    }
    
    [cache setObject: rv forKey: name];
    return rv;
}
