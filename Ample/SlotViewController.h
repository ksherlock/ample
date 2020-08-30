//
//  SlotViewController.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/18/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SlotViewController : NSViewController

@property (nonatomic) NSString *model;
@property (nonatomic) NSDictionary *machine;

@property NSString *memory;
@property NSUInteger memoryBytes;

@property NSString *sl0;
@property NSString *sl1;
@property NSString *sl2;
@property NSString *sl3;
@property NSString *sl4;
@property NSString *sl5;
@property NSString *sl6;
@property NSString *sl7;

@property NSString *rs232;
@property NSString *aux;
@property NSString *exp;
@property NSString *gameio;
@property NSString *printer;
@property NSString *modem;

@property NSSize resolution;

@property NSArray *args;
@property NSDictionary *media;

//-(void)setMachine: (NSDictionary *)machine;

- (IBAction)menuChanged:(id)sender;
- (IBAction)memoryMenuChanged:(id)sender;

-(IBAction)resetSlots: (id)sender;
@end

NS_ASSUME_NONNULL_END
