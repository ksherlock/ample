//
//  DiskImagesWindowController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiskImagesWindowController : NSWindowController <NSWindowRestoration>

+(instancetype)sharedInstance;

@end

@interface DiskImagesWindowController (TableView) <NSTableViewDelegate, NSTableViewDataSource>

@end

@interface DiskImagesWindowController (Menu) <NSMenuDelegate>

@end


NS_ASSUME_NONNULL_END
