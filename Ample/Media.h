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
    unsigned midiin;
    unsigned midiout;
    unsigned picture;
    uint64_t floppy_mask;
} Media;


typedef enum {
    MediaTypeError = -1,
    MediaTypeUnknown = 0,
    MediaType_5_25,
    MediaType_3_5,
    MediaType_HardDisk,
    MediaType_CDROM,
    MediaType_Cassette,
    MediaType_Picture,
    MediaType_MIDI,
} MediaType;

struct Media MediaFromDictionary(NSDictionary *);

void MediaAdd(Media *dest, const Media *src);

BOOL MediaEqual(const Media *lhs, const Media *rhs);

extern const Media EmptyMedia;

MediaType ClassifyMediaFile(id file);

#endif /* Media_h */
