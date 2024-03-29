//
//  BookmarkManager.h
//  Ample
//
//  Created by Kelvin Sherlock on 6/1/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NSMenu;
@class NSMenuItem;
@class Bookmark;
@class DiskImage;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *updateMenuItem;
@property (readonly) NSManagedObjectContext *managedObjectContext;

@property (nullable) Bookmark *currentBookmark;

+(instancetype)sharedManager;

-(NSString *)uniqueBookmarkName: (NSString *)name;

-(NSError *)saveBookmark: (NSDictionary *)bookmark name: (NSString *)name automatic: (BOOL)automatic;

//-(NSError *)saveDefault: (NSDictionary *)bookmark;

-(Bookmark *)defaultBookmark;
-(NSDictionary *)loadDefault;

-(NSError *)setAutomatic: (Bookmark *)bookmark;

-(BOOL)addDiskImage: (NSObject *)pathOrURL;

//-(void)convertLegacyBookmarks;
@end

NS_ASSUME_NONNULL_END
