//
//  DownloadWindowController.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/2/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadWindowController : NSWindowController <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property NSString *currentROM;
@property NSInteger currentCount;
@property NSInteger totalCount;
@property NSInteger errorCount;
@property BOOL active;

@end

NS_ASSUME_NONNULL_END
