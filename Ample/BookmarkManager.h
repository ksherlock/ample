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
@class Bookmark;
@class DiskImage;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

@property (weak) IBOutlet NSMenu *menu;
@property (readonly) NSManagedObjectContext *managedObjectContext;

+(instancetype)sharedManager;

-(NSString *)uniqueBookmarkName: (NSString *)name;

-(NSError *)saveBookmark: (NSDictionary *)bookmark name: (NSString *)name automatic: (BOOL)automatic;

//-(NSError *)saveDefault: (NSDictionary *)bookmark;

-(NSDictionary *)loadDefault;

-(NSError *)setAutomatic: (Bookmark *)bookmark;

-(BOOL)addDiskImage: (NSObject *)pathOrURL;


//-(void)convertLegacyBookmarks;
@end

NS_ASSUME_NONNULL_END
