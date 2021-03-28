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


NSURL *MameURL(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];
        
    if ([defaults boolForKey: kUseCustomMame]) {
        NSString *path = [defaults stringForKey: kMamePath];
        if (![path length]) return [NSURL fileURLWithPath: path];
    }
    
    return [bundle URLForAuxiliaryExecutable: @"mame64"];
}

NSString *MamePath(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];

    NSString *path;
    
    if ([defaults boolForKey: kUseCustomMame]) {
        path = [defaults stringForKey: kMamePath];
        if ([path length]) return path;
    }
    path = [bundle pathForAuxiliaryExecutable: @"mame64"];
    if ([path length]) return path;
    return nil;
}


NSURL *MameWorkingDirectory(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
    if ([defaults boolForKey: kUseCustomMame]) {
        NSString *path = [defaults stringForKey: kMameWorkingDirectory];
        if (![path length]) return [NSURL fileURLWithPath: path];
    }
    
    return SupportDirectory();
}

NSString *MameWorkingDirectoryPath(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
    if ([defaults boolForKey: kUseCustomMame]) {
        NSString *path = [defaults stringForKey: kMameWorkingDirectory];
        if (![path length]) return path;
    }
    
    return SupportDirectoryPath();
}


NSDictionary *MameMachine(NSString *machine) {
    static NSMutableDictionary *cache;
    
    if (!cache) cache = [NSMutableDictionary new];
    NSDictionary *d;
    
    if (!machine) return nil;
    d = [cache objectForKey: machine];
    if (d) return d;

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: machine withExtension: @"plist"];
    
    d = [NSDictionary dictionaryWithContentsOfURL: url];
    if (d) [cache setObject: d forKey: machine];
    return d;
}

/* NSCache doesn't retain it's key. This essentially interns it. */
/* could just abuse NSSelectorFromString() */
NSString *InternString(NSString *key) {
    static NSMutableSet *storage = nil;
    
    if (!storage) {
        storage = [NSMutableSet new];
    }
    NSString *copy = [storage member: key];
    if (!copy) {
        copy = [key copy];
        [storage addObject: copy];
    }
    return copy;
}


NSString *kUseCustomMame = @"UseCustomMame";
NSString *kMamePath = @"MamePath";
NSString *kMameWorkingDirectory = @"MameWorkingDirectory";
NSString *kAutoCloseLogWindow = @"AutoCloseLogWindow";
NSString *kMameComponentsDate = @"MameComponentsDate";
NSString *kDefaultDownloadURL = @"DefaultDownloadURL";
NSString *kDefaultDownloadExtension = @"DefaultDownloadExtension";

NSString *kDownloadURL = @"DownloadURL";
NSString *kDownloadExtension = @"DownloadExtension";
