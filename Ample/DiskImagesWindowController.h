//
//  DiskImagesWindowController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiskImagesWindowController : NSWindowController

@end

@interface DiskImagesWindowController (TableView) <NSTableViewDelegate, NSTableViewDataSource>

@end


NS_ASSUME_NONNULL_END
