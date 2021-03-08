//
//  Media.m
//  Ample
//
//  Created by Kelvin Sherlock on 3/7/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Media.h"

const Media EmptyMedia = { 0 };

struct Media MediaFromDictionary(NSDictionary *dict) {
    
    Media m = { 0 };

#define _(name) m.name = [[dict objectForKey: @ # name] unsignedIntValue]
    _(cass);
    _(cdrom);
    _(hard);
    _(floppy_3_5);
    _(floppy_5_25);
    _(pseudo_disk);

    return m;
#undef _
}

void MediaAdd(Media *dest, const Media *src) {

    if (!src || !dest) return;

#define _(name) dest->name += src->name;
    _(cass);
    _(cdrom);
    _(hard);
    _(floppy_3_5);
    _(floppy_5_25);
    _(pseudo_disk);
#undef _
}

BOOL MediaEqual(const Media *lhs, const Media *rhs) {
    if (lhs == rhs) return YES;
    if (!lhs || !rhs) return NO;
    

#define _(name) if (lhs->name != rhs->name) return NO;
    _(cass);
    _(cdrom);
    _(hard);
    _(floppy_3_5);
    _(floppy_5_25);
    _(pseudo_disk);
    return YES;
#undef _
}
