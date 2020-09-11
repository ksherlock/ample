//
//  NewSlotViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/9/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewSlotViewController : NSViewController

@property NSArray *args;
@property NSDictionary *media;
@property NSSize resolution;
@property (nonatomic) NSString *machine;
@end

@interface NewSlotViewController (OutlineView) <NSOutlineViewDelegate, NSOutlineViewDataSource>

@end

@interface SlotTableCellView  : NSTableCellView

@property (weak) IBOutlet NSPopUpButton *menuButton;

@end


@interface SlotItem : NSObject
@property unsigned index;
@property NSArray *children;
@property NSArray *menuItems;
@property NSInteger defaultIndex;
@property NSInteger selectedIndex;

-(NSDictionary *)selectedItem;
-(NSDictionary *)selectedMedia;
-(BOOL)hasDefault;

-(void)reset;
@end


NS_ASSUME_NONNULL_END
