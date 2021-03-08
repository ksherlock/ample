//
//  NewSlotViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/9/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Media.h"

NS_ASSUME_NONNULL_BEGIN

@interface NewSlotViewController : NSViewController

@property NSArray *args;
@property Media media;
@property NSSize resolution;
@property (nonatomic) NSString *machine;
@end

@interface NewSlotViewController (OutlineView) <NSOutlineViewDelegate, NSOutlineViewDataSource>

@end




NS_ASSUME_NONNULL_END
