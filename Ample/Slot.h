//
//  Slot.h
//  Ample
//
//  Created by Kelvin Sherlock on 3/6/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Media.h"

//NS_ASSUME_NONNULL_BEGIN
@class Slot, SlotOption, SlotTableCellView;


@interface Slot : NSObject<NSCopying>

@property NSInteger defaultIndex;
@property NSInteger selectedIndex;
@property NSInteger index;

@property (readonly) NSString *name;
@property (readonly) NSString *title;
@property (readonly) NSArray *menuItems;


-(NSArray *)args;
-(NSArray *)serialize;

-(void)reset;
-(void)prepareView: (SlotTableCellView *)view;

-(void)selectValue: (NSString *)value;
-(SlotOption *)selectedItem;
-(Media)selectedMedia;

-(NSArray *)selectedChildren;

@end

@interface SlotOption : NSObject<NSCopying>

@property NSString *value;
@property NSString *title;
@property BOOL isDefault;
@property BOOL disabled;

@end

@interface SlotTableCellView  : NSTableCellView

@property (weak) IBOutlet NSPopUpButton *menuButton;

@end


//NS_ASSUME_NONNULL_END
