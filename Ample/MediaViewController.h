//
//  MediaViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/20/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Media.h"
#import "Ample.h"

NS_ASSUME_NONNULL_BEGIN

@interface MediaViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic) Media media;
@property NSArray *args;

- (IBAction)ejectAction:(id)sender;
- (IBAction)pathAction:(id)sender;

@end

@interface MediaViewController (Bookmark) <Bookmark>

@end



NS_ASSUME_NONNULL_END
