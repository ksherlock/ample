//
//  DiskImage+CoreDataProperties.h
//  Ample
//
//  Created by Kelvin Sherlock on 2/7/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import "DiskImage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DiskImage (CoreDataProperties)

+ (NSFetchRequest<DiskImage *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *path;
@property (nullable, nonatomic, copy) NSDate *added;
@property (nonatomic) int64_t size;
@property (nullable, nonatomic, copy) NSDate *accessed;
@property (nullable, nonatomic, copy) NSString *name;

-(void)updatePath;

@end

NS_ASSUME_NONNULL_END
