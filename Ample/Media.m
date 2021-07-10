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
    _(bitbanger);

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
    _(bitbanger);
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
    _(bitbanger);
    return YES;
#undef _
}


#include <unistd.h>
#include <sys/stat.h>



#define _x2(a,b) (a | (b << 8))
#define _x3(a,b,c) (a | (b << 8) | (c << 16))
#define _x4(a,b,c, d) (a | (b << 8) | (c << 16) | (d << 24))
static unsigned hash(const char *cp) {
    unsigned rv = 0;
    int i, shift;
    if (!cp) return 0;
    for (i = 0, shift = 0; i < 4; ++i, shift += 8) {
        unsigned c = cp[i];
        if (!c) break;
        c = tolower(c);
        rv |= (c << shift);
    }
    //if (i > 4) return 0; // .image is 5....
    return rv;
}

const char *extname(const char *path) {
    
    const char *rv = NULL;
    if (!path) return path;
    for(unsigned i = 0; ; ++i) {
        unsigned c = path[i];
        if (c == 0) break;
        if (c == '/') rv = NULL;
        if (c == '.') rv = path + i + 1;
    }
    if (rv && !*rv) rv = NULL;
    return rv;
}

/*
 * MAME cares deeply about file extensions. LIST NOT EXHAUSTIVE
 *
 * Hard Disk: .chd  .hd   .hdv  .2mg  .hdi
 * CD-ROM: .chd  .cue  .toc  .nrg  .gdi  .iso  .cdr
 * 5.25: .dsk .do .po  .edd  .woz  .nib .mfi  .dfi  .rti
 * 3.5: .dc42 .woz .2mg .mfi  .dfi  .hfe  .mfm  .td0  .imd
        .d77  .d88  .1dd  .cqm .cqi  .dsk  .ima  .img  .ufi
        .360  .ipf [also .po and .hdv]
 * Midi in: .mid
 * Midi out: .mid
 * Picture: .png
 * Cassette: .wav
 */

static bool is_raw_525(size_t disk_size) {
    if (disk_size & 255) return NO;
    size_t blocks = disk_size >> 8;
    
    return blocks == 560 || blocks == 640;
}

static BOOL is_raw_35(size_t disk_size) {
    if (disk_size & 511) return NO;
    size_t blocks = disk_size >> 9;

    return blocks == 800 || blocks == 1600 || blocks == 1440 || blocks == 2880;
}

static MediaType is_woz(const uint8_t *buffer, size_t file_size) {

    /* woz 1/2 ? */
    if (!memcmp(buffer, "WOZ1\xff\x0a\x0d\x0a", 8) || !memcmp(buffer, "WOZ2\xff\x0a\x0d\x0a", 8)) {

        if (!memcmp(buffer + 12, "INFO", 4)) {
            unsigned type = buffer[21]; // 1 = 5.25, 2 = 3.5
            if (type == 1) return MediaType_5_25;
            if (type == 2) return MediaType_3_5;
        }
        return MediaTypeUnknown;
    }
    return MediaTypeError;
}

static MediaType is_dc42(const uint8_t *buffer, size_t file_size) {

    if (buffer[0x52] == 0x01 && buffer[0x53] == 0x00 && buffer[0] >= 1 && buffer[0] <= 0x3f) {
        int dsize = OSReadBigInt32(buffer, 0x40);
        int tsize = OSReadBigInt32(buffer, 0x44);
        if (dsize + tsize + 0x54 == file_size) {
            if (is_raw_35(dsize)) return MediaType_3_5;
            return MediaType_HardDisk;
        }
    }

    return MediaTypeError;
}

static MediaType is_2img(const uint8_t *buffer, size_t file_size) {

    if (!memcmp(buffer, "2IMG", 4)) {
        int format = OSReadLittleInt32(buffer, 0x0c); // 0 - dos order, 1 = prodos order, 2 = nib data
        int blocks = OSReadLittleInt32(buffer, 0x14); // prodos only.
        //int bytes = OSReadLittleInt32(buffer, 0x1c);
        
        if (format == 2 || format == 0) return MediaType_5_25; // nib and dos order
        if (is_raw_525(blocks * 512))  return MediaType_5_25;
        if (is_raw_35(blocks * 512)) return MediaType_3_5;
        return MediaType_HardDisk; //
        //return MediaTypeUnknown;
    }

    return MediaTypeError;
}

static MediaType is_chd(const uint8_t *buffer, size_t file_size) {
    if (!memcmp(buffer, "MComprHD", 8)) {
        static int offsets[] = { 0, 0, 0, 28, 28, 32}; // offset for logival bytes.
        int version = OSReadBigInt32(buffer, 12);

        if (version >= 3 && version <= 5) {
            long bytes = OSReadBigInt64(buffer, offsets[version]);
            if (is_raw_525(bytes)) return MediaType_5_25;
            if (is_raw_35(bytes)) return MediaType_3_5;
            return MediaType_HardDisk; // iso?
        }
        return MediaTypeUnknown;
    }
    return MediaTypeError;
}



MediaType ClassifyMediaFile(id file) {
    
    struct stat st;
    ssize_t size;
    unsigned char buffer[128];
    int fd;
    const char *path = [file fileSystemRepresentation]; // or URL
    const char *ext = extname(path);
    unsigned ext_hash = hash(ext);

    memset(&st, 0, sizeof(st));
    memset(buffer, 0, sizeof(buffer));

    fd = open(path, O_RDONLY);
    if (fd < 0) return MediaTypeError;
    fstat(fd, &st);
    
    size = read(fd, buffer, sizeof(buffer));
    close(fd);
    if (size <= 0) return MediaTypeError;

    // 13 sector support ? not on an event 512 block boundary.
    // = 116480 bytes.
    
    switch(ext_hash) {
        case _x3('w', 'o', 'z'):
            return is_woz(buffer, st.st_size);

        case _x3('2', 'm', 'g'):
        case _x4('2', 'i', 'm', 'g'):
            return is_2img(buffer, st.st_size);

        case _x3('c', 'h', 'd'):
            return is_chd(buffer, st.st_size);

        // dc42 - dc,dc42,dsk,img,image
        case _x2('d', 'c'): // n.b. as of .233, allowed for mac, not for apple2
        case _x4('d', 'c', '4', '2'):
            return is_dc42(buffer, st.st_size);

            // dsk, image, img may also be raw or disk copy.
        case _x3('d', 's', 'k'):
        case _x3('i', 'm', 'g'):
        case _x4('i', 'm', 'a', 'g'):

            if (is_raw_525(st.st_size)) return MediaType_5_25;
            if (is_raw_35(st.st_size)) return MediaType_3_5;
            return is_dc42(buffer, st.st_size);

        case _x2('d', 'o'):
        case _x2('p', 'o'):
            if (is_raw_525(st.st_size)) return MediaType_5_25;
            if (is_raw_35(st.st_size)) return MediaType_3_5;
            return MediaTypeUnknown;

        // hdv - 3.5 or hard drive.
        case _x3('h', 'd', 'v'):
        case _x3('r', 'a', 'w'):
            if (is_raw_35(st.st_size)) return MediaType_3_5;
            if ((st.st_size & 511) == 0) return MediaType_HardDisk;
            return MediaTypeUnknown;
            
        case _x3('n', 'i', 'b'):
            return MediaType_5_25;

        case _x3('w', 'a', 'v'):
            return MediaType_Cassette;

        // cd-rom
        case _x3('i', 's', 'o'):
        case _x3('c', 'u', 'e'):
        case _x3('c', 'd', 'r'):
            return MediaType_CDROM;

        case _x3('p', 'n', 'g'):
            return MediaType_Picture;

        case _x3('m', 'i', 'd'):
            return MediaType_MIDI;

    }

    return MediaTypeUnknown;
    
}
