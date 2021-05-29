//
//  TransparentScroller.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/4/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "TransparentScroller.h"

@implementation TransparentScroller

- (void)drawRect:(NSRect)dirtyRect {
    //[super drawRect:dirtyRect];
    [[NSColor clearColor] set];
    NSRectFill(dirtyRect);

#if 0
    NSColor *color = _backgroundColor;
    if (color) {
        [color setFill];
        NSRectFill(dirtyRect);
    }
#endif
    [self drawKnob];
}

@end
