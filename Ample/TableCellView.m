//
//  TableCellView.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "TableCellView.h"
#import "MidiManager.h"
#import "Menu.h"


@implementation MediaTableCellView
#if 0
{
    NSTrackingRectTag _trackingRect;
}
#endif
-(void)awakeFromNib {

    // need to do it here for 10.11 compatibility.

    if (@available(macOS 10.14, *)) {
        NSValueTransformer *t;
        NSDictionary *options;

        t = [NSValueTransformer valueTransformerForName: @"ValidColorTransformer"];
        options = @{ NSValueTransformerBindingOption: t};
        [_ejectButton bind: @"contentTintColor" toObject: self withKeyPath: @"objectValue.valid" options: options];
    } else {
        // El Capitan TODO...
    }
    
}

-(void)prepareView: (NSInteger)category {
}

#if 0
-(void)awakeFromNib {
    
    // this is apparently necessary for setTintColor to work.
    NSImage *img;
    img = [_ejectButton image];
    [img setTemplate: YES];
    img = [_ejectButton alternateImage];
    [img setTemplate: YES];
}
#endif

/* mouse tracking to enable/disable dragger image -- no longer used.*/
#if 0
-(void)viewDidMoveToSuperview {
    if (_trackingRect) {
        [self removeTrackingRect: _trackingRect];
    }
    NSRect rect = [_dragHandle frame];
    _trackingRect = [self addTrackingRect: rect owner: self userData: NULL assumeInside:NO];
}

-(void)mouseEntered:(NSEvent *)event {
    [_dragHandle setHidden: NO];
}

-(void)mouseExited:(NSEvent *)event {
    [_dragHandle setHidden: YES];
}
#endif

@end

@implementation PathTableCellView

-(void)prepareView: (NSInteger)category {
    [_pathControl setTag: category + 1];
}

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu {
    // if this is an output path, replace the "choose..." button with a save panel.
    NSMenuItem *item = [menu itemAtIndex: 0];
    if (item) {
        [item setTarget: self];
        [item setAction: @selector(choosePath:)];
    }
}

-(IBAction)choosePath:(id)sender {
    NSPathControl *pc = _pathControl;
    NSURL *url = [pc URL];
    
    NSSavePanel *p = [NSSavePanel savePanel];

    if (url) {
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL dir = NO;
        NSString *str = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
        [fm fileExistsAtPath: str isDirectory: &dir];

        if (!dir) {
            [p setNameFieldStringValue: [str lastPathComponent]];
            url = [url URLByDeletingLastPathComponent];
        }
        [p setDirectoryURL: url];
    }
    [p setExtensionHidden: NO];

    [p beginWithCompletionHandler: ^(NSModalResponse response){
        if (response != NSModalResponseOK) return;
        NSURL *url = [p URL];
        [pc setURL: url];
    }];
    
}

@end


@interface EmptyStringTransformer : NSValueTransformer

@end

static NSString *kNone = @"—None—";

@implementation EmptyStringTransformer

+(void)load {
    [self setValueTransformer: [self new] forName: @"EmptyStringTransformer"];
}

+ (Class)transformedValueClass {
    return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
    return YES;
}
- (id)transformedValue:(id)value {
    if (value == nil) return kNone;
    if ([kNone isEqualToString: value]) return nil;
    return value;
}

@end

@implementation MidiTableCellView {
    NSInteger _category;
}

/* binding should be able to handle the menu but i couldn't make it work. */


-(void)prepareView: (NSInteger)category {
    _category = category;

    // 10.11 + doesn't need to remove the observer in the -dealloc
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector: @selector(midiChanged:) name: category == kIndexMidiIn ? kMidiSourcesChangedNotification : kMidiDestinationsChangedNotification object: nil];

    [self updateMenus: NO];
}

-(void)updateMenus: (BOOL)notification {
    NSMenu *menu = [_popUpButton menu];
    MidiManager *mgr = [MidiManager sharedManager];
    
    NSArray *array = _category == kIndexMidiIn ? [mgr sources] : [mgr destinations];

    NSString *selected = [[_popUpButton selectedItem] title];
    [menu removeAllItems];
    int selectedIndex = -1;
    NSMenuItem *item;

    item = [[NSMenuItem alloc] initWithTitle: kNone action: NULL keyEquivalent: @""];
    [item setAttributedTitle: ItalicMenuString(kNone)];
    [menu addItem: item];
    selectedIndex = 0;
#if 0
    if (!selected || [@"" isEqualToString: selected]) {
        selectedIndex = 0;
    }
#endif
    
    int ix = 1;
    for (NSString *s in array) {
        item = [[NSMenuItem alloc] initWithTitle: s action: NULL keyEquivalent: @""];
        [item setRepresentedObject: s];
        [menu addItem: item];
        if ([s isEqualToString: selected]) {
            selectedIndex = ix;
        }
        ++ix;
    }

    // does this propogate?
    [_popUpButton selectItemAtIndex: selectedIndex];
    if (notification) [_popUpButton sendAction: [_popUpButton action] to: [_popUpButton target]];
}

-(void)midiChanged: (NSNotification *)notification {
    
    [self updateMenus: YES];
}


-(void)prepareForReuse {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    _category = 0;
    [super prepareForReuse];
}

@end
