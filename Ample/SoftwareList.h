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
#import "AutocompleteControl.h"


@interface SoftwareList : NSObject <AutocompleteItem>
@property NSString *name;
@property NSString *title;
@property NSArray *items;
@property NSString *notes;

-(SoftwareList *)filter: (NSString *)filter;

@end

@interface Software : NSObject <AutocompleteItem>
@property NSString *name;
@property NSString *title;
@property NSString *compatibility;
@property NSString *list;
@property NSString *notes;

-(NSString *)fullName;

@end

@interface SoftwareSet : NSObject <NSFastEnumeration, AutoCompleteDelegate>

+(instancetype)softwareSetForMachine: (NSString *)machine;
-(BOOL)nameIsUnique: (NSString *)name;

-(NSString *)nameForSoftware: (Software *)software;
-(Software *)softwareForName: (NSString *)name;

-(BOOL)hasSoftware: (Software *)software;
@end


//NSArray<SoftwareList *> *SoftwareListForMachine(NSString *machine);


#endif /* SoftwareList_h */
