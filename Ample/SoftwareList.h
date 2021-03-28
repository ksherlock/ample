//
//  SoftwareList.h
//  Ample
//
//  Created by Kelvin Sherlock on 3/28/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#ifndef SoftwareList_h
#define SoftwareList_h

#import <Foundation/Foundation.h>

@interface SoftwareList : NSObject
@property NSString *name;
@property NSString *title;
@property NSArray *items;
@end

@interface Software : NSObject
@property NSString *name;
@property NSString *title;
@end


NSArray<SoftwareList *> *SoftwareListForMachine(NSString *machine);


#endif /* SoftwareList_h */
