//
//  EjectButton.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/7/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "EjectButton.h"

static NSImage *ejectImage = nil;
static NSImage *ejectHoverImage = nil;

@implementation EjectButton {
    NSTrackingRectTag _tracking;
}

+(void)initialize {
    // content tint only works with template images.
    ejectImage = [NSImage imageNamed: @"eject-16x16"];
    ejectHoverImage = [NSImage imageNamed: @"eject-hover-16x16"];
    [ejectImage setTemplate: YES];
    [ejectHoverImage setTemplate: YES];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setButtonType: NSButtonTypeMomentaryPushIn];
    [self setImage: ejectImage];
    [self setAlternateImage: ejectHoverImage];
    _tracking = [self addTrackingRect: [self bounds] owner: self userData: nil assumeInside: NO];
}

-(void)mouseEntered:(NSEvent *)event {
    if ([self isEnabled])
        [self setImage: ejectHoverImage];
}
-(void)mouseExited:(NSEvent *)event {
    [self setImage: ejectImage];
}

@end
