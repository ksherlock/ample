//
//  ROMBrowserDelegate.h
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ROMBrowserDelegate : NSObject <NSBrowserDelegate>

@property NSString *model;

@end

NS_ASSUME_NONNULL_END
