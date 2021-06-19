//
//  LogWindowController.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogWindowController : NSWindowController <NSWindowDelegate>

#if 0
+(id)controllerForTask: (NSTask *)task;
+(id)controllerForTask: (NSTask *)task close: (BOOL)close;
#endif

+(id)controllerForArgs: (NSArray *)args;
+(id)controllerForArgs: (NSArray *)args close: (BOOL)close;
@end

NS_ASSUME_NONNULL_END
