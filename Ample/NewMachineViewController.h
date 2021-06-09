//
//  NewMachineViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 6/8/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Ample.h"

NS_ASSUME_NONNULL_BEGIN

@interface NewMachineViewController : NSViewController

@property (nullable) NSString *machine;

@end

@interface NewMachineViewController (Table) <NSOutlineViewDelegate, NSOutlineViewDataSource>

@end

@interface NewMachineViewController (Bookmark) <Bookmark>

@end

NS_ASSUME_NONNULL_END
