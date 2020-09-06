//
//  MediaViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic) NSDictionary *media;
@property NSArray *args;

- (IBAction)ejectAction:(id)sender;
- (IBAction)pathAction:(id)sender;


//-(void)setMedia: (NSDictionary *)media;

@end



@interface TablePathView : NSTableCellView
@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSButton *ejectButton;
@property (weak) IBOutlet NSImageView *dragHandle;
@end

NS_ASSUME_NONNULL_END
