//
//  LogWindowController.h
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogWindowController : NSWindowController <NSWindowDelegate>

+(id)controllerForTask: (NSTask *)task;

@end

NS_ASSUME_NONNULL_END
