//
//  TableCellView.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "TableCellView.h"



@implementation TablePathView {
    NSTrackingRectTag _trackingRect;
}

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

