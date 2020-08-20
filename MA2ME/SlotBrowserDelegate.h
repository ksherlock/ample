//
//  SlotBrowserDelegate.h
//  MA2ME
//
//  Created by Kelvin Sherlock on 8/16/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SlotBrowserDelegate : NSObject <NSBrowserDelegate>

@property (nonatomic) NSString *model;

@property (weak) NSBrowser *browser;

@property NSString *slot0;
@property NSString *slot1;
@property NSString *slot2;
@property NSString *slot3;
@property NSString *slot4;
@property NSString *slot5;
@property NSString *slot6;
@property NSString *slot7;
@property NSString *slot8;

@property NSString *exp;
@property NSString *aux;

@property NSString *gameio;
@property NSString *printer;
@property NSString *modem;
@property NSString *rs232;
@end

NS_ASSUME_NONNULL_END
