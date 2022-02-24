//
//  DiskImage+CoreDataProperties.m
//  Ample
//
//  Created by Kelvin Sherlock on 2/7/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import "DiskImage+CoreDataProperties.h"

#if 0
@interface DiskImage () {
    NSString *_name;
}
@end
#endif

@implementation DiskImage (CoreDataProperties)

+ (NSFetchRequest<DiskImage *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"DiskImage"];
}

@dynamic path;
@dynamic added;
@dynamic size;
@dynamic accessed;
@dynamic name;

-(void)updatePath {

    NSString *path = [self primitiveValueForKey: @"path"];
    [self setName: [path lastPathComponent]];
}

-(void)awakeFromFetch {
    [super awakeFromFetch];

    [self updatePath];
}

#if 0
-(void)awakeFromInsert {
    [super awakeFromInsert];

    NSString *path = [self primitiveValueForKey: @"path"];
    [self setName: [path lastPathComponent]];
}
#endif

@end
