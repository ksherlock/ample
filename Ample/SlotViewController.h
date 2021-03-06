//
//  SlotViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/9/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Media.h"
#import "Ample.h"

NS_ASSUME_NONNULL_BEGIN

@interface SlotViewController : NSViewController

@property NSArray *args;
@property Media media;
@property NSSize resolution;
@property (nonatomic, nullable) NSString *machine;

-(IBAction)resetSlots:(nullable id)sender;

@end

@interface SlotViewController (OutlineView) <NSOutlineViewDelegate, NSOutlineViewDataSource>

@end

@interface SlotViewController (Bookmark) <Bookmark>

@end


NS_ASSUME_NONNULL_END
