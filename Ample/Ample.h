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

/* ~/Library/ApplicationSupport/Ample/ */
NSURL *SupportDirectory(void);
NSString *SupportDirectoryPath(void);

/* mame executable URL */
NSURL *MameURL(void);
NSString *MamePath(void);

/* mame working directory */
NSURL *MameWorkingDirectory(void);
NSString *MameWorkingDirectoryPath(void);

NSString *InternString(NSString *key);

NSDictionary *MameMachine(NSString *machine);

/* NSUserDefaults keys */
extern NSString *kUseCustomMame;
extern NSString *kMamePath;
extern NSString *kMameWorkingDirectory;
extern NSString *kAutoCloseLogWindow;
extern NSString *kMameComponentsDate;

extern NSString *kDownloadURL;
extern NSString *kDownloadExtension;

extern NSString *kDefaultDownloadURL;
extern NSString *kDefaultDownloadExtension;

#endif /* Ample_h */
