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

-(void)viewDidMoveToSuperview {
    return;
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

@end

