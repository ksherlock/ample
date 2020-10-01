//
//  Ample.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/1/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#ifndef Ample_h
#define Ample_h

#import <Cocoa/Cocoa.h>

NSURL *SupportDirectory(void);
NSString *SupportDirectoryPath(void);

/* NSUserDefaults keys */
extern NSString *kUseCustomMame;
extern NSString *kMamePath;
extern NSString *kMameWorkingDirectory;
extern NSString *kAutoCloseLogWindow;
extern NSString *kMameComponentsDate;

#endif /* Ample_h */
