//
//  Bookmark+CoreDataClass.h
//  Ample
//
//  Created by Kelvin Sherlock on 2/6/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Bookmark : NSManagedObject

@property NSDictionary *dictionary;

+(NSString *)uniqueName: (NSString *)name inContext: (NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "Bookmark+CoreDataProperties.h"
