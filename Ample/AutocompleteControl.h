//
//  AutocompleteControl.h
//  Autocomplete
//
//  Created by Kelvin Sherlock on 2/20/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class AutocompleteControl;

@protocol AutocompleteItem
-(NSString *)menuTitle;
-(NSAttributedString *)menuAttributedTitle; //?? can it still handle color?
-(BOOL)menuEnabled;
-(BOOL)menuIsHeader;
@end


@protocol AutoCompleteDelegate

-(NSArray<id<AutocompleteItem>> *)autocomplete: (AutocompleteControl *)control completionsForString: (NSString *)string;
-(NSArray<id<AutocompleteItem>> *)autocomplete: (AutocompleteControl *)control completionsForItem: (id<AutocompleteItem>)item;

@end

@interface AutocompleteControl : NSSearchField

@property NSInteger minWidth;
@property NSInteger maxDisplayItems;
@property (nullable, weak) id<AutoCompleteDelegate> autocompleteDelegate;

-(void)invalidate;


@end


NS_ASSUME_NONNULL_END
