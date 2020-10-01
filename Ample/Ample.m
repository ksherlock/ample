//
//  Ample.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/1/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#include "Ample.h"

NSURL *SupportDirectory(void) {
    static NSURL *cached = nil;
    
    if (!cached) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;

        NSURL *url = [fm URLForDirectory: NSApplicationSupportDirectory inDomain: NSUserDomainMask appropriateForURL: nil create: YES error: &error];
        cached = [url URLByAppendingPathComponent: @"Ample"];
        
        [fm createDirectoryAtURL: cached withIntermediateDirectories: YES attributes: nil error: &error];
    }
    return cached;
    
}

NSString *SupportDirectoryPath(void) {
    static NSString *cached = nil;
    
    if (!cached) {
        NSURL *url = SupportDirectory();
        cached = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
    }
    return cached;
}


NSString *kUseCustomMame = @"UseCustomMame";
NSString *kMamePath = @"MamePath";
NSString *kMameWorkingDirectory = @"MameWorkingDirectory";
NSString *kAutoCloseLogWindow = @"AutoCloseLogWindow";
NSString *kMameComponentsDate = @"MameComponentsDate";
