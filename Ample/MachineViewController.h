//
//  MachineViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Ample.h"

NS_ASSUME_NONNULL_BEGIN

@interface MachineViewController : NSViewController <NSBrowserDelegate>

@property NSString *machine;

@end

@interface MachineViewController (Bookmark) <Bookmark>

@end

NS_ASSUME_NONNULL_END
