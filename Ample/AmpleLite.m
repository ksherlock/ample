//
//  AmpleLite.m
//  Ample Lite
//
//  Created by Kelvin Sherlock on 6/14/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMenuItem;

@interface SUUpdater : NSObject
@end

@implementation  SUUpdater

- (IBAction)checkForUpdates:(id)sender {
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return NO;
}

@end
