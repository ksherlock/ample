//
//  Menu.m
//  Ample
//
//  Created by Kelvin Sherlock on 10/3/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NSFont *ItalicMenuFont(void) {
    NSFont *font = [NSFont menuFontOfSize: 0];
    NSFontDescriptor *fd = [font fontDescriptor];
    NSFontDescriptor *fd2 = [fd fontDescriptorWithSymbolicTraits: NSFontDescriptorTraitItalic];
    return [NSFont fontWithDescriptor: fd2 size: [font pointSize]];
}

NSAttributedString *ItalicMenuString(NSString *s) {
    static NSDictionary *attr = nil;
    if (!attr) {
        attr = @{
            NSFontAttributeName: ItalicMenuFont()
        };
    }
    return [[NSAttributedString alloc] initWithString: s attributes: attr];
}
