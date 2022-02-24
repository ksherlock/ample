//
//  Bookmark+CoreDataProperties.m
//  Ample
//
//  Created by Kelvin Sherlock on 2/6/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import "Bookmark+CoreDataProperties.h"

@implementation Bookmark (CoreDataProperties)

+ (NSFetchRequest<Bookmark *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
}

@dynamic name;
@dynamic machine;
@dynamic data;
@dynamic created;
@dynamic modified;
@dynamic comment;
@dynamic automatic;

@end
