//
//  TableCellView.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//NS_ASSUME_NONNULL_BEGIN



@interface TablePathView : NSTableCellView
@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSButton *ejectButton;
@property (weak) IBOutlet NSImageView *dragHandle;
@property BOOL movable;
@end

//NS_ASSUME_NONNULL_END
