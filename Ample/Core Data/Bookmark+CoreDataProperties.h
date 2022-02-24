//
//  Bookmark+CoreDataProperties.h
//  Ample
//
//  Created by Kelvin Sherlock on 2/6/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import "Bookmark+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Bookmark (CoreDataProperties)

+ (NSFetchRequest<Bookmark *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *machine;
@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, copy) NSDate *created;
@property (nullable, nonatomic, copy) NSDate *modified;
@property (nullable, nonatomic, copy) NSString *comment;
@property (nonatomic) BOOL automatic;
@end

NS_ASSUME_NONNULL_END
