//
//  Slot.m
//  Ample
//
//  Created by Kelvin Sherlock on 3/6/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Slot.h"

static NSArray *MapArray(NSArray *src, id(^fn)(id)) {
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity: [src count]];
    for (id x in src) {
        [rv addObject: fn(x)];
    }
    return rv;
}


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

-(instancetype)initWithDictionary: (NSDictionary *)dictionary devices: (NSDictionary *)devices;

@end

@interface SlotOption() {
    //NSArray<Slot *> *_children;
    //NSDictionary *_media;
    Media _media;
    NSString *_keyPath;
    //NSString *_devName;
    BOOL _default;
}

@property (readonly) NSArray *children;

-(instancetype)initWithDictionary: (NSDictionary *)dictionary devices: (NSDictionary *)devices;

-(NSMenuItem *)menuItem;

-(void)reset;

-(NSString *)keyPath;
-(void)setKeyPath: (NSString *)path;
-(void)buildArgs: (NSMutableArray *)args;
-(void)buildMedia: (Media *)media;
-(void)buildSerial: (NSMutableDictionary *)array;


-(void)reserialize: (NSDictionary *)dict;

//-(BOOL)loadDeviceSlots: (NSDictionary *)devices;

@end

@implementation Slot

static NSDictionary *IndexMap = nil;
+(void)load {
    
    IndexMap = @{
        @"ramsize":    @0,
        @"sl0":        @1,
        @"sl1":        @2,
        @"sl2":        @3,
        @"sl3":        @4,
        @"sl4":        @5,
        @"sl5":        @6,
        @"sl6":        @7,
        @"sl7":        @8,
        @"exp":        @9,
        @"aux":        @10,
        @"rs232":      @11,
        @"gameio":     @12,
        @"modem":      @13,
        @"printer":    @14,

        //nubus mac
        @"nb9":        @15,
        @"nba":        @16,
        @"nbb":        @17,
        @"nbc":        @18,
        @"nbd":        @19,
        @"nbe":        @20,

        @"smartport":  @21,
        @"bios":       @22,
    };
    static_assert(kSMARTPORT_SLOT == 21, "Smartport != 21");
    static_assert(kBIOS_SLOT == 22, "Bios != 22");
}

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

-(NSDictionary *)serialize {
    if (_selectedIndex < 0) return nil;
    
    NSMutableDictionary *d = [NSMutableDictionary new];
    SlotOption *option = [_options objectAtIndex: _selectedIndex];
    [option buildSerial: d];
    //if (![d count]) return nil; //?
    return d;
}

-(void)reserialize: (NSDictionary *)dict {
    // { 'sl3' : 'uthernet' }

    // special case for smartport since the name isn't used.
    if (_index == kSMARTPORT_SLOT) {
        SlotOption *option = [_options objectAtIndex: _selectedIndex];
        [option reserialize: dict];
        return;
    }
    // special case for child options since _name is incorrect.
    // _name is :rs232.  should be set to -sl3:ssc:rs232 :/
#if 0
    if (!_title) {

        BOOL found = NO;
        unsigned ix = 0;
        for (SlotOption *option in _options) {
            NSString *keyPath = [option keyPath];
            NSString *value = [dict objectForKey: keyPath];
            if (value && [value isEqualToString: [option value]]) {
                [self setSelectedIndex: ix];
                [option reserialize: dict];
                found = YES;
                break;
            }
            ++ix;
        }
        return;
    }
#endif
    
    NSString *value = [dict objectForKey: _name];
    if (!value) {
        //[self reset];
        return;
    }
    // find it...
    BOOL found = NO;
    unsigned ix = 0;
    for (SlotOption *option in _options) {
        if ([value isEqualToString: [option value]]) {
            
            [self setSelectedIndex: ix];
            [option reserialize: dict];
            found = YES;
            break;
        }
        ++ix;
    }
    
}


-(Media)selectedMedia {

    if (_selectedIndex < 0) return EmptyMedia;

    Media media = { 0 };
    SlotOption *option = [_options objectAtIndex: _selectedIndex];

    [option buildMedia: &media];
    return media;

}


-(NSArray *)selectedChildren {
    if (_selectedIndex < 0) return nil;
    return [[_options objectAtIndex: _selectedIndex] children];
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
    
// extra logic for -fdc:0, -0, -sl6:0, etc, built-in slots.
    unichar c = [_name characterAtIndex: 0];
    NSString *p = nil;
    if (c == ':') p = [path stringByAppendingString: _name];
    else if (c == '-') p = _name;
    else p = [@"-" stringByAppendingString: _name];
    for (SlotOption *o in _options) {
        [o setKeyPath: p];
    }
    
    // set up child name so bookmarks work.
    if (c == ':') _name = p;
}


-(instancetype)initWithDictionary: (NSDictionary *)data devices: (NSDictionary *)devices {

    BOOL topLevel = NO;
    _selectedIndex = -1;
    _defaultIndex = -1;
    _index = -1;
    
    _name = [data objectForKey: @"name"];
    _title = [data objectForKey: @"description"];
    
    NSNumber *x = [IndexMap objectForKey: _name];
    if (x) {
        topLevel = YES;
        _index = [x integerValue];
        _name = [@"-" stringByAppendingString: _name];
        _title = [_title stringByAppendingString: @":"];
    }
    
    NSArray *op = [data objectForKey: @"options"];
    NSMutableArray *options = [NSMutableArray arrayWithCapacity: [op count]];

    
    NSInteger index = 0;
    for (NSDictionary *d in op) {
        SlotOption *o = [[SlotOption alloc] initWithDictionary: d devices: devices];
        if ([o isDefault]) {
            _defaultIndex = index;
        }
        ++index;
        if (topLevel) {
            [o setKeyPath: _name];
            NSArray *tmp = [o children];
            for (Slot *x in tmp) {
                [x setIndex: _index | 0x10000];
            }
        }
        [options addObject: o];
    }
    _options = options;
    
    _selectedIndex = _defaultIndex;
    if (_selectedIndex < 0) _selectedIndex = 0;


    //if (topLevel) [self setKeyPath];
    
    return self;
}

#if 0
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
#endif

-(NSArray *)menuItems {
    //if (_menuItems) return _menuItems;

    NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity: [_options count]];
    for (SlotOption *o in _options) {
        [menuItems addObject: [o menuItem]];
    }
    //_menuItems = tmp;
    return menuItems;
}

#if 0
-(void)loadDeviceSlots: (NSDictionary *)devices {
    for (SlotOption *s in _options) {
        [s loadDeviceSlots: devices];
    }
}
#endif

-(void)prepareView: (SlotTableCellView *)view {
    
    // can't cache the menu items since they
    // may still be in use.
    
    NSButton *hb = [view hamburgerButton];
    NSPopUpButton *button = [view menuButton];
    NSTextField *text = [view textField];
    
    [view setObjectValue: self];
    
    [text setObjectValue: _title];
    [button unbind: @"selectedIndex"];
    NSMenu *menu = [button menu];
    NSArray *menuItems = [self menuItems];

    // [menu setItemArray: ] doesn't work prior to 10.14, apparently.
    [menu removeAllItems];
    if (_index == kSMARTPORT_SLOT) {
        //[menu setItemArray: @[]];
        [button setHidden: YES];
    } else {
        //[menu setItemArray: menuItems];
        for (NSMenuItem *x in menuItems) [menu addItem: x];
        [button bind: @"selectedIndex" toObject: self withKeyPath: @"selectedIndex" options: nil];
        [button setHidden: NO];
    }
    [button setTag: _index];

    [hb setTag: _index];
    // hb visible status bound in xib.
}

/*
https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html
 */
+ (NSSet *)keyPathsForValuesAffectingSelectedItem {
    return [NSSet setWithObject: @"selectedIndex"];
}

@end


@implementation SlotOption

@synthesize  isDefault = _default;

#if 0
-(instancetype)initWithDictionary: (NSDictionary *)dictionary {
    
    _default = [(NSNumber *)[dictionary objectForKey: @"default"] boolValue];
    _disabled = [(NSNumber *)[dictionary objectForKey: @"disabled"] boolValue];
    _value = [dictionary objectForKey: @"value"];
    //_devName = [dictionary objectForKey: @"devName"];
    _title = [dictionary objectForKey: @"description"];
    _media = MediaFromDictionary([dictionary objectForKey: @"media"]);
    //_media = [dictionary objectForKey: @"media"];
    return self;
}
#endif

-(instancetype)initWithDictionary: (NSDictionary *)data devices: (NSDictionary *)devices {
    
    _default = [(NSNumber *)[data objectForKey: @"default"] boolValue];
    _disabled = [(NSNumber *)[data objectForKey: @"disabled"] boolValue];
    _value = [data objectForKey: @"value"];
    _title = [data objectForKey: @"description"];
    _media = MediaFromDictionary([data objectForKey: @"media"]);
    
    NSString *devName = [data objectForKey: @"devname"];
    if (devName && devices) {
        
        NSArray *tmp = [devices objectForKey: devName];
        if (tmp) _children = DeepCopyArray(tmp);
    }
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
    //child->_devName = [_devName copyWithZone: zone];
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
    _(bitbanger);
    _(midiin);
    _(midiout);
    _(picture);
#undef _
        
    for (Slot *s in _children) {
        [[s selectedItem] buildMedia: media];
    }
}

-(void)reserialize: (NSDictionary *)dict {
    
#if 0
    NSString *value = [dict objectForKey: _keyPath];
    if (value) {
        // don't need to do anything since set by slot.
    }
#endif
    for (Slot *s in _children) {
        [s reserialize: dict];
    }
}

-(void)buildSerial: (NSMutableDictionary *)dict {

    if (!_default)
        [dict setObject: _value forKey: _keyPath];

    for (Slot *s in _children)
        [[s selectedItem] buildSerial: dict];

}


// propogate
-(void)setKeyPath: (NSString *)path {
    
    _keyPath = path;
    if (!_children) return;
    NSString *p = path;
    if ([_value length]) p = [path stringByAppendingFormat: @":%@", _value];
    
    for (Slot *s in _children) {
        [s setKeyPath: p];
    }
}
-(NSString *)keyPath {
    return _keyPath;
}

#if 0
-(BOOL)loadDeviceSlots: (NSDictionary *)devices {
    NSArray *o = [devices objectForKey: _devName];
    if (!o) return NO;
    _children = DeepCopyArray(o);
    return YES;
}
#endif

@end


@implementation SlotTableCellView

@end


extern NSString *InternString(NSString *);

NSDictionary *BuildDevices(NSArray *array) {

#if 0
    static NSCache *cache = nil;

    if (!cache) {
        cache = [NSCache new];
    }
#endif

    NSMutableDictionary *rv = [NSMutableDictionary dictionaryWithCapacity: [array count]];
    for (NSDictionary *d in array) {
        NSString *name = [d objectForKey: @"name"];
        NSArray *slots = [d objectForKey: @"slots"];
        
        if (!name) continue;
        if (!slots) continue;

#if 0
        name = InternString(name);
        id x = [cache objectForKey: name];
        if (x) {
            [rv setObject: x forKey: name];
            continue;
        }
#endif

        NSArray *data = MapArray(slots, ^(id o){
            
            Slot *s = [[Slot alloc] initWithDictionary: o devices: nil];
            return s;
        });
        
        [rv setObject: data forKey: name];
    }
    return rv;
}
NSArray *BuildSlots(NSString *name, NSDictionary *data) {

    static NSCache *cache = nil;

    if (!cache) {
        cache = [NSCache new];
    }
    
    
    name = InternString(name);
    NSArray *x = [cache objectForKey: name];
    if (x) {
        return x;
    }
    
    NSArray *slots = [data objectForKey: @"slots"];

    NSMutableArray *rv = [NSMutableArray arrayWithCapacity: [slots count]];

    NSDictionary *devices = BuildDevices([data objectForKey: @"devices"]);
    for (NSDictionary *d in slots) {
        
        Slot *s = [[Slot alloc] initWithDictionary: d devices: devices];
        [rv addObject: s];
    }
    
    [cache setObject: rv forKey: name];
    return rv;
}
