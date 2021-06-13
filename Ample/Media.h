//
//  Media.h
//  Ample
//
//  Created by Kelvin Sherlock on 3/7/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#ifndef Media_h
#define Media_h


typedef struct Media {
    unsigned cass;
    unsigned cdrom;
    unsigned hard;
    unsigned floppy_5_25;
    unsigned floppy_3_5;
    unsigned pseudo_disk;
    unsigned bitbanger;
} Media;

struct Media MediaFromDictionary(NSDictionary *);

void MediaAdd(Media *dest, const Media *src);

BOOL MediaEqual(const Media *lhs, const Media *rhs);

extern const Media EmptyMedia;

#endif /* Media_h */
