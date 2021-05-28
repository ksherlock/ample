//
//  AutocompleteControl.m
//  Autocomplete
//
//  Created by Kelvin Sherlock on 2/20/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import "AutocompleteControl.h"
#include <wctype.h>


/*
 
Todo --
- when there is a value, can filter the list by only including header items and the selected value
- draw inactive menu items
- when menu is hidden then text is manually deleted (not esc canceled), then down/up arrow the list needs to update.
- eliminate nib and do it manually.
- when menus is too tall, macos moves it to the top of the screen.
 - 1. it's not moved someplace more appropriate when the size shrinks
 - 2. it should display to the left or right in that case.
 - need to know parent's frame.
 
 - fuzzy search - minimum distance between letters?
 */


@interface ACMenuView : NSView
@property (nonatomic) NSArray<id<AutocompleteItem>> *items;

@property (weak) AutocompleteControl *parent;

-(void)reset;
@end


@interface AutocompleteControl ()
{
    IBOutlet NSPanel *_panel;
    __weak IBOutlet ACMenuView *_menuView;
    __weak IBOutlet NSScrollView *_scrollView;
    
    id<AutocompleteItem> _value;
    BOOL _editing;
    BOOL _dirty;
}

@end

@interface AutocompleteControl (SearchField) <NSSearchFieldDelegate>
-(void)fixTextColor: (BOOL)editing;
@end

@implementation AutocompleteControl

-(void)_init {
    
    [self setDelegate: self];
    [self setPlaceholderString: @""];
    [(NSSearchFieldCell *)[self cell] setSearchButtonCell: nil];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSNib *nib = [[NSNib alloc] initWithNibNamed: @"Autocomplete" bundle: bundle];
    
    NSArray *topLevel = nil;
    [nib instantiateWithOwner: self topLevelObjects: &topLevel];
    
    [_panel setMovable: NO];
    [_panel setBecomesKeyOnlyIfNeeded: YES];
    [_menuView setParent: self];
}

-(id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame: frameRect])) {
        [self _init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder: coder])) {
        [self _init];
    }
    return self;
}

#if 0
-(NSString *)stringValue {
    return [super stringValue];
}
#endif

-(id)objectValue {
    return _value;
}

-(void)setStringValue:(NSString *)stringValue {
    [super setStringValue: stringValue];
    if (_value && [[_value menuTitle] isEqualToString: stringValue] == NO)
        _value = nil;
    
    // todo -- search for a matching item, update text color.
}

-(void)setObjectValue:(id)objectValue {
    if (_value == objectValue) return;
    if (![objectValue conformsToProtocol: @protocol(AutocompleteItem)]) {
        _value = nil;
        [super setStringValue: @""];
        return;
    }
    _value = objectValue;
    if (!_value) [super setStringValue: @""]; //
    else {
        [super setStringValue: [_value menuTitle]];
        NSArray *array = [_autocompleteDelegate autocomplete: self completionsForItem: _value];
        [_menuView setItems: array];
    }
}

-(BOOL)valid {
    return _value != nil;
}


-(void)hideSuggestions: (id)sender {
    
    if (![_panel isVisible]) return;

    NSWindow *window = [self window];

    [window removeChildWindow: _panel];
    [_panel orderOut: sender];
    
}

-(void)showSuggestions: (id)sender {
    
    if ([_panel isVisible]) return;
    NSWindow *window = [self window];
    
    NSRect wFrame = [_panel frame];
    NSRect vFrame = [self frame];
    
    NSRect rect = { .origin = vFrame.origin, .size = wFrame.size };
    rect = [window convertRectToScreen:rect];

    rect.origin.y -= wFrame.size.height + 4;
    rect.size.width = MAX(vFrame.size.width, _minWidth);
    // todo - min width option.
    [_panel setFrame: rect display: YES];
    
    //[_panel setFrameOrigin: rect.origin];
    [window addChildWindow: _panel ordered: NSWindowAbove];
}

-(void)updateSuggestions {

    if (!_autocompleteDelegate) return;
    NSString *needle = [self stringValue];

    NSArray *items = [_autocompleteDelegate autocomplete: self completionsForString: needle];
    
    [_menuView setItems: items];
    if ([items count]) {
        [self showSuggestions: nil];
    } else {
        [self hideSuggestions: nil];
    }
}

-(void)invalidate {
    
    if (!_autocompleteDelegate) return;

    NSArray *items = nil;

    /* if there is an object value, try to retain it. */
    if (_value) {
        
        [_menuView reset];
        items = [_autocompleteDelegate autocomplete: self completionsForItem: _value];
        if (items) {
            [_menuView setItems: items];
            return;
        }
        _value = nil;
        [self invoke];
    }
    NSString *needle = [self stringValue];

    if ([needle length]) {
        _dirty = YES;
    }
    // if only 1 match, auto-set value?
    items = [_autocompleteDelegate autocomplete: self completionsForString: needle];
    [self fixTextColor: _editing];
    [_menuView setItems: items];
}


// prevent action messages from the search field/cell.
-(BOOL)sendAction:(SEL)action to:(id)target {
    if (action == [self action] && target == [self target]) return NO;
    return [super sendAction: action to: target];

}

-(void)invoke {
    _dirty = NO;
    [super sendAction: [self action] to: [self target]];
}

@end


@implementation AutocompleteControl (SearchField)

-(void)fixTextColor: (BOOL)editing {
    NSColor *color = editing || _value ? [NSColor controlTextColor] : [NSColor systemRedColor];
    [self setTextColor: color];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    //NSLog(@"controlTextDidChange");

    if (_value) {
        _dirty = YES;
        _value = nil;
    }
    
    NSString *s = [self stringValue];
    if ([s length]) {
        [self updateSuggestions];
    } else {
        _dirty = YES;
        _value = nil;
        [_menuView reset];
        [_menuView setItems: nil];
        [self hideSuggestions: nil];
        [self invoke];
    }
}
- (void)controlTextDidBeginEditing:(NSNotification *)obj {
    //NSLog(@"controlTextDidBeginEditing");

    _editing = YES;
    _dirty = NO;
    [self fixTextColor: YES];
}



- (void)controlTextDidEndEditing:(NSNotification *)obj {
    //NSLog(@"controlTextDidEndEditing");

    _editing = NO;

    [self hideSuggestions: nil];

    if (_dirty) {
        _value = nil;
        [self invoke];
    }
    [self fixTextColor: NO];
}


-(BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    return YES;
}

-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    return YES;
}

-(void)selectItem:(id<AutocompleteItem>)item withSelector:(SEL)selector {
    
    // for newline/mousedown, will still retain focus after updating
    // so we need to invalidate the value if it's edited further.
    if (selector == @selector(insertNewline:) || selector == @selector(mouseDown:) || selector == @selector(insertTab:)) {

        _value = item;
        NSString *str = [item menuTitle];

        [super setStringValue: str];
        
        [self hideSuggestions: nil];
        
        NSText *fieldEditor = [self currentEditor];
        //[fieldEditor setSelectedRange: NSMakeRange([str length], 0)];
        [fieldEditor setSelectedRange: NSMakeRange(0, [str length])];

        [self invoke];
        
        // need to invalidate the menu so it reloads
        

#if 0
        NSArray *array = [_autocompleteDelegate autocomplete: self completionsForItem: _value];
        [_menuView setItems: array];
#else
        [_menuView setItems: nil];
#endif
        
        //NSLog(@"selectItem:withSelector:");
    }
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(moveUp:)) {
        //[self showSuggestions: nil];
        if ([_panel isVisible]) {
            [_menuView moveUp: textView];
        } else {
            [self updateSuggestions];
        }
        return YES;
    }
    
    if (commandSelector == @selector(moveDown:)) {
        //[self showSuggestions: nil];
        if ([_panel isVisible]) {
            [_menuView moveDown: textView];
        } else {
            [self updateSuggestions];
        }
        return YES;
    }

    if (commandSelector == @selector(insertNewline:)) {
        if ([_panel isVisible])
            [_menuView insertNewline: textView];
        return YES;
    }

    if (commandSelector == @selector(insertTab:)) {
        if ([_panel isVisible])
            [_menuView insertTab: textView];
        return NO;
    }
    
    if (commandSelector == @selector(complete:)) {
        if ([_panel isVisible]) {
            [self hideSuggestions: nil];
        } else {
            [self updateSuggestions];
        }
        return YES;
    }

    
    // esc ?
    // if panel open, hide
    // if panel closed, delete.
    if (commandSelector == @selector(cancelOperation:)) {
        
        if ([_panel isVisible]) {
            [self hideSuggestions: nil];
        } else {
            _value = nil;
            [super setStringValue: @""];

            [self hideSuggestions: nil];
            [_menuView reset];
            //[_menuView setItems: _completions];
            // sigh...
    #if 0
            NSArray *items =[_autocompleteDelegate autocomplete: self completionsForString: @""];
            [_menuView setItems: items];
    #endif
            [self invoke];
        }
        return YES;
    }
    
    //NSLog(@"%@", NSStringFromSelector(commandSelector));
    return NO;
}


@end


@interface ACMenuView () {
    id<AutocompleteItem> _value;
    NSInteger _index;
    NSInteger _count;
    NSArray<id<AutocompleteItem>> *_items;
    NSTrackingArea *_trackingArea;
    NSColor *_backgroundColor;
    NSColor *_selectedColor;
    BOOL _tracking;
    BOOL _clipped;
}
@end

@implementation ACMenuView

#define MENU_FONT_SIZE 11
#define MENU_HEIGHT 14
#define MARGIN_TOP 0 //6
#define MARGIN_BOTTOM 0 //6
#define INDENT 7
#define HEADER_INDENT 7
#define MAX_DISPLAY_ITEMS 16


-(void)_init {
    _backgroundColor = [NSColor windowBackgroundColor];
    _selectedColor = [NSColor selectedContentBackgroundColor];
    
    NSTrackingAreaOptions options = NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveInActiveApp;
    _trackingArea = [[NSTrackingArea alloc] initWithRect: NSZeroRect
                                                 options: options
                                                   owner: self
                                                userInfo: nil];

    [self addTrackingArea: _trackingArea];
}

-(id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder: coder])) {
        [self _init];
    }
    return self;
    
}

-(BOOL)isFlipped {
    return YES;
}

-(BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

static CGFloat HeightForItems(NSUInteger count) {
    return count * MENU_HEIGHT;
}

-(NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoIntrinsicMetric, _count * MENU_HEIGHT + MARGIN_TOP + MARGIN_BOTTOM);
}

- (NSSize)sizeThatFits:(NSSize)size {
    size.height = _count * MENU_HEIGHT + MARGIN_TOP + MARGIN_BOTTOM;
    return size;
}

- (void)sizeToFit {
    NSSize size = [self frame].size;
    size.height = _count * MENU_HEIGHT + MARGIN_TOP + MARGIN_BOTTOM;
    [self setFrameSize: size];
    [self setNeedsDisplay: YES];
}

-(void)reset {
    [self invalidateRow: _index];
    _index = -1;
    _value = nil;
    _items = nil;
}

-(void)setItems:(NSArray *)items {
    if (_items == items) return;
    _items = [items copy];
    _index = -1;
    _count = [items count];

    
    if (!_items) return;

    // also check enabled status....
    if (_value) {
        _index = [_items indexOfObject: _value];
        if (_index == NSNotFound) {
            _index = -1;
            _value = nil;
        }
    }

    // if only 1 entry, auto-select it.
    if (!_value) {
        NSInteger count = -1;
        for (id<AutocompleteItem> item in _items) {
            ++count;
            if ([item menuIsHeader]) continue;
            if (_value) {
                _value = nil;
                _index = -1;
                break;
            }
            _value = item;
            _index = count;
        }
    }
    

    
    NSInteger displayCount = MIN(_count,  MAX_DISPLAY_ITEMS);
    CGFloat newHeight = HeightForItems(displayCount) + 8 ; // 4px top/bottom
    NSWindow *window = [self window];
    NSRect wFrame = [window frame];
    
    NSRect contentRect = [[[self enclosingScrollView] contentView] frame];

    //NSSize size = [self intrinsicContentSize];
    //NSInteger minWidth = [_parent minWidth];
    //size.width = MAX(wFrame.size.width, minWidth);
    //size.height += 8;
    
    CGFloat delta = wFrame.size.height - newHeight;
    
    wFrame.origin.y += delta;
    wFrame.size.height = newHeight;
    
    _clipped = (_count > displayCount);

    [self setFrameSize: NSMakeSize(contentRect.size.width /*- 15.0*/, HeightForItems(_count))];
    [self setNeedsDisplay: YES];
    [window setFrame: wFrame display: YES];

    if (_value) {
        [self scrollToRow: _index position: ScrollToCenter force: NO];
    } else {
        [self scrollToRow: 0 position: ScrollToTop force: YES];
    }
    
    //[self sizeToFit];
    //[[self window] setContentSize: [self frame].size];
    
    //NSLog(@"%@", NSStringFromRect(wFrame));
}

-(id<AutocompleteItem>)itemAtPoint: (NSPoint)point indexPtr: (NSInteger *)indexPtr {

    NSInteger index = floor(point.y / MENU_HEIGHT);
    if (index < 0 || index >= _count) return nil;
    if (indexPtr) *indexPtr = index;
    return [_items objectAtIndex: index];
}

enum {
    ScrollToTop,
    ScrollToBottom,
    ScrollToCenter,
};

-(void)scrollToRow: (NSInteger)row position: (unsigned)position force: (BOOL)force {
    if (row < 0) return;
    if (!_clipped) return;

    NSScrollView *scrollView = [self enclosingScrollView];
    NSClipView *clipView = [scrollView contentView];

    NSRect visibleRect = [self visibleRect];
    if (!force) {
        NSRect mRect = NSMakeRect(0, row * MENU_HEIGHT, 1 , MENU_HEIGHT);
        if (NSContainsRect(visibleRect, mRect)) return;
    }
        
    NSInteger topRow = row;
    switch (position) {
        case ScrollToTop:
            break;
        case ScrollToBottom:
            topRow -= MAX_DISPLAY_ITEMS -1;
            break;
        case ScrollToCenter:
            topRow -= MAX_DISPLAY_ITEMS/2 - 1;
            break;
    }
    if (topRow < 0) topRow = 0;
    if (topRow > _count - MAX_DISPLAY_ITEMS)
        topRow = _count - MAX_DISPLAY_ITEMS;
    NSPoint point = NSMakePoint(0, topRow * MENU_HEIGHT);
    
    //[self scrollClipView: clipView toPoint: point];
    [clipView scrollToPoint: point];
    [scrollView reflectScrolledClipView: clipView];

}


-(void)moveUp:(id)sender {
    if (_count == 0 || _index <= 0) return;
    
    NSInteger index = 0;
    id<AutocompleteItem> value = nil;
    for (index = _index - 1; index >= 0; --index) {
        value = [_items objectAtIndex: index];
        if ([value menuIsHeader]) continue;
        if (![value menuEnabled]) continue;
        break;
    }
    if (index < 0) return;
    if (index == _index) return;
    [self invalidateRow: _index];
    [self invalidateRow: index];

    _index = index;
    _value = value;
    [self scrollToRow: index position: ScrollToTop force: NO];
    [_parent selectItem: _value withSelector: _cmd];
}

-(void)moveDown:(id)sender {

    // _index -1 selects first item.
    if (_count == 0  || _index == _count - 1) return;
    
    NSInteger index = 0;
    id<AutocompleteItem> value = nil;
    for (index = _index + 1; index < _count ; ++index) {
        value = [_items objectAtIndex: index];
        if ([value menuIsHeader]) continue;
        if (![value menuEnabled]) continue;
        break;
    }
    if (index == _count) return;
    if (index == _index) return;
    [self invalidateRow: _index];
    [self invalidateRow: index];

    _index = index;
    _value = value;

    [self scrollToRow: index position: ScrollToBottom force: NO];
    [_parent selectItem: _value withSelector: _cmd];
}

-(void)insertNewline:(id)sender {
    if (_value) {
        [_parent selectItem: _value withSelector: _cmd];
    }
}

-(void)insertTab:(id)sender {
    // if only one option, autocomplete?
    if (_value) {
        [_parent selectItem: _value withSelector: _cmd];
    }
}

-(void)mouseMoved:(NSEvent *)event {
    //NSLog(@"mouse moved");

    if (!_tracking) return;

    NSPoint p = [event locationInWindow];
    p = [self convertPoint: p fromView: nil];
    
    
    NSInteger index;
    id<AutocompleteItem> value = [self itemAtPoint: p indexPtr: &index];
    if (!value) return;
    if (index == _index) return;
    if ([value menuIsHeader]) return;
    if (![value menuEnabled]) return;

    [self invalidateRow: _index];
    [self invalidateRow: index];

    _index = index;
    _value = value;
    [_parent selectItem: _value withSelector: _cmd];
}
-(void)mouseDown:(NSEvent *)event {
    if (!_tracking) return;

    NSPoint p = [event locationInWindow];
    p = [self convertPoint: p fromView: nil];
    
    NSInteger index;
    id<AutocompleteItem> value = [self itemAtPoint: p indexPtr: &index];
    if (!value) return;
    if (index != _index) {
        if ([value menuIsHeader]) return;
        if (![value menuEnabled]) return;

        [self invalidateRow: _index];
        [self invalidateRow: index];

        _index = index;
        _value = value;
    }
    
    [_parent selectItem: _value withSelector: _cmd];
}

-(void)mouseEntered:(NSEvent *)event {
    //NSLog(@"mouse entered");
    _tracking = YES;

}
-(void)mouseExited:(NSEvent *)event {
    //NSLog(@"mouse exited");

    _tracking = NO;
}

-(void)invalidateRow:(NSInteger)row {
    if (row < 0 || row >= _count) return;
    
    NSRect r = NSZeroRect;
    NSRect bounds = [self bounds];

    r.size.width = bounds.size.width;
    r.size.height = MENU_HEIGHT;
    r.origin.y = MENU_HEIGHT * row + MARGIN_TOP;
    //NSLog(@"Invalidating %ld - %@", row, NSStringFromRect(r));
    [self setNeedsDisplayInRect: r];
}


static void DrawString(NSString *str, NSDictionary *attr, CGRect rect) {
    
    NSSize size = [str sizeWithAttributes: attr];
    if (size.width <= rect.size.width) {
        [str drawInRect: rect withAttributes: attr];
        return;
    }
    NSMutableString *mstr = [str mutableCopy];
    // binary search is probably the best way to handle it :/
    NSInteger l = [mstr length];
    while (l > 2) {
        [mstr replaceCharactersInRange: NSMakeRange(l-2, 2) withString: @"…"];
        --l;
        size = [mstr sizeWithAttributes: attr];
        if (size.width <= rect.size.width) {
            [mstr drawInRect: rect withAttributes: attr];
            return;
        }
    }
}

-(void)drawItem: (id<AutocompleteItem>)item inRect: (NSRect)rect {
    NSColor *textColor = [NSColor textColor];
    if (!item) return;

    if (item == _value) {
        textColor = [NSColor selectedMenuItemTextColor];
        [_selectedColor setFill];
        NSRectFill(rect);
    }
    NSString *string = [item menuTitle];

    if ([item menuIsHeader]) {
        textColor = [NSColor secondaryLabelColor];
        NSDictionary *attr = @{
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: [NSFont systemFontOfSize: MENU_FONT_SIZE], // [NSFont boldSystemFontOfSize: 13],
        };
        NSRect r  = NSInsetRect(rect, HEADER_INDENT, 0);
        DrawString(string, attr, r);
    } else {

        NSDictionary *attr = @{
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: [NSFont systemFontOfSize: MENU_FONT_SIZE],
        };
        NSRect r  = NSInsetRect(rect, INDENT, 0);
        r.origin.x += INDENT;
        r.size.width -= INDENT;
        DrawString(string, attr, r);
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSRect r = [self bounds];
    NSInteger begin = floor((NSMinY(dirtyRect) - MARGIN_TOP) / MENU_HEIGHT);
    NSInteger end = ceil((NSMaxY(dirtyRect) - MARGIN_TOP) / MENU_HEIGHT);
    if (begin < 0) begin = 0;
    if (end > _count) end = _count;

    
    r.origin.y = MENU_HEIGHT * begin + MARGIN_TOP;
    r.size.height = MENU_HEIGHT;
    for (NSInteger index = begin; index < end; ++index) {
        id<AutocompleteItem> item = [_items objectAtIndex: index];
        [self drawItem: item inRect: r];
        r.origin.y += MENU_HEIGHT;
    }
}

@end


/* custom scroller that doesn't draw a background. */
@interface ACScroller : NSScroller
@end

@implementation ACScroller


-(void)drawRect:(NSRect)dirtyRect {
    [[NSColor windowBackgroundColor] set];
    NSRectFill(dirtyRect);
    [self drawKnob];
}

@end


@interface ACPanel : NSPanel
@end

@implementation ACPanel

/* needed to prevent the pop-up child window from being moved when offscreen. */
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    return frameRect;
}


@end
