//
//  BookmarkManager.h
//  Ample
//
//  Created by Kelvin Sherlock on 6/1/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMenu;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

@property (weak) IBOutlet NSMenu *menu;

+(instancetype)sharedManager;

-(void)loadBookmarks;
-(void)updateMenu;

-(BOOL)validateName: (NSString *)name;

-(BOOL)saveBookmark: (NSDictionary *)bookmark name: (NSString *)name;
-(NSDictionary *)loadBookmarkFromURL: (NSURL *)url;

-(BOOL)saveDefault: (NSDictionary *)bookmark;
-(NSDictionary *)loadDefault;

@end

NS_ASSUME_NONNULL_END
