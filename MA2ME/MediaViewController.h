//
//  MediaViewController.h
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (weak) IBOutlet NSOutlineView *outlineView;

- (IBAction)buttonDelete:(id)sender;

@end



@interface TablePathView : NSTableCellView
@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSButton *deleteButton;

@end

NS_ASSUME_NONNULL_END
