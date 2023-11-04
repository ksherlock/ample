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


typedef enum SlotType {
    kSlotRAM = 1,
    kSlotBIOS,
    kSlotFDC,
} SlotType;

@interface Slot : NSObject<NSCopying>

@property NSInteger defaultIndex;
@property NSInteger selectedIndex;
@property NSInteger index;

@property (readonly) NSString *name;
@property (readonly) NSString *title;
@property (readonly) NSArray *menuItems;
@property (readonly) SlotType type;

@property (readonly) SlotOption *selectedItem;
@property (readonly) NSString *selectedValue;

-(NSArray *)args;
-(NSDictionary *)serialize;
-(void)reserialize: (NSDictionary *)dict;

-(void)reset;
-(void)prepareView: (SlotTableCellView *)view;

-(void)selectValue: (NSString *)value;

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
@property (weak) IBOutlet NSButton *hamburgerButton;
@end


//NS_ASSUME_NONNULL_END
