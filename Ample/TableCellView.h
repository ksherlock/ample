//
//  TableCellView.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//NS_ASSUME_NONNULL_BEGIN


enum {
    kIndexFloppy525 = 0,
    kIndexFloppy35,
    kIndexHardDrive,
    kIndexCDROM,
    kIndexCassette,
    kIndexDiskImage,
    kIndexBitBanger,
    kIndexMidiIn,
    kIndexMidiOut,
    kIndexPicture, // computer eyes -pic, .png only.
    kIndexROM,
    // kIndexPrintout // -prin, .prn extension only?
    
    kIndexLast
};
#define CATEGORY_COUNT 11
static_assert(kIndexLast == CATEGORY_COUNT, "Invalid Category Count");


@interface MediaTableCellView : NSTableCellView
@property (weak) IBOutlet NSButton *ejectButton;
@property (weak) IBOutlet NSImageView *dragHandle;
@property BOOL movable;

-(void)prepareView: (NSInteger)category;
@end

@interface PathTableCellView : MediaTableCellView <NSPathControlDelegate>
@property (weak) IBOutlet NSPathControl *pathControl;
@end


@interface MidiTableCellView : MediaTableCellView
@property (weak) IBOutlet NSPopUpButton *popUpButton;
@end

//NS_ASSUME_NONNULL_END
