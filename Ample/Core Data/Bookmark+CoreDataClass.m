//
//  Bookmark+CoreDataClass.m
//  Ample
//
//  Created by Kelvin Sherlock on 2/6/2022.
//  Copyright © 2022 Kelvin Sherlock. All rights reserved.
//
//

#import "Bookmark+CoreDataClass.h"

@implementation Bookmark

/* extract the number from a trailing " (%d)" */
static int extract_number(NSString *s, NSInteger offset) {
    
    unichar buffer[32];
    NSInteger len = [s length] - offset;
    unichar c;
    int i;
    int n = 0;
    
    if (len < 4) return -1; /* " (1)"*/
    if (len > 6) return -1; /* " (999)" */
    
    NSRange r = NSMakeRange(offset, len);
    [s getCharacters: buffer range: r];
    
    buffer[len] = 0;
    i = 0;
    if (buffer[i++] != ' ') return -1;
    if (buffer[i++] != '(') return -1;
    
    c = buffer[i++];
    if (c < '1' || c > '9') return -1;
    n = c - '0';
    
    for (;;) {
        c = buffer[i];
        if (c < '0' || c > '9') break;
        n = n * 10 + (c - '0');
        ++i;
    }

    if (buffer[i++] != ')') return -1;
    if (buffer[i++] != 0) return -1;

    return n;
}

+(NSString *)uniqueName: (NSString *)name inContext: (NSManagedObjectContext *)context {
    
    NSInteger length = [name length];

    NSError *error = nil;
    NSPredicate *p = [NSPredicate predicateWithFormat: @"name BEGINSWITH %@", name];
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName: @"Bookmark"];
    [req setPredicate: p];

    NSArray *array = [context executeFetchRequest: req error: &error];
    if (![array count]) return name;

    uint64_t bits = 1; /* mark 0 as unavailable */
    NSInteger max = 0;
    BOOL exact = NO;
    for (Bookmark *b in array) {
        NSString *s = [b name];
        if ([name isEqualToString: s]) {
            exact = YES;
            continue;
        }
        int n = extract_number(s, length);
        if (n < 1) continue;
        if (n > max) max = n;
        if (n < 64)
            bits |= (1 << n);
    }
    if (!exact) return name;
    
    if (bits == (uint64_t)-1) {
        if (max == 999) return nil;
        return [name stringByAppendingFormat: @" (%u)", (int)(max + 1)];
    }
    
#if 1
    int ix = 0;
    while (bits) {
        ++ix;
        bits >>= 1;
    }
#else
    // this doesn't work correctly.
    int ix = __builtin_ffsll(~bits);
#endif
    return [name stringByAppendingFormat: @" (%u)", ix];

}

-(void)setDictionary:(NSDictionary *)dictionary {
    
    NSData *data;
    NSError *error = nil;

    data = [NSPropertyListSerialization dataWithPropertyList: dictionary
                                                      format: NSPropertyListBinaryFormat_v1_0
                                                     options: 0
                                                       error: &error];
    
    [self setData: data];
}

-(NSDictionary *)dictionary {
    
//    NSDictionary *dict;
    NSData *data = [self data];
    NSError *error = nil;
    
    return [NSPropertyListSerialization propertyListWithData: data
                                                     options: 0
                                                      format: nil
                                                       error: &error];
}


- (NSError *)errorFromOriginalError:(NSError *)originalError error:(NSError*)secondError
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSMutableArray *errors = [NSMutableArray arrayWithObject:secondError];
    if ([originalError code] == NSValidationMultipleErrorsError) {
        [userInfo addEntriesFromDictionary:[originalError userInfo]];
        [errors addObjectsFromArray:[userInfo objectForKey:NSDetailedErrorsKey]];
    } else {
        [errors addObject:originalError];
    }
    [userInfo setObject:errors forKey:NSDetailedErrorsKey];
    return [NSError errorWithDomain:NSCocoaErrorDomain code:NSValidationMultipleErrorsError userInfo:userInfo];
}

- (BOOL)validateName:(id*)ioValue error:(NSError**)outError {
    
    if (!ioValue || !*ioValue) return YES;
    NSString *name = *ioValue;
    
    NSFetchRequest *frq = [NSFetchRequest fetchRequestWithEntityName: @"Bookmark"];
    
    NSPredicate *p = [NSPredicate predicateWithFormat: @"name = %@", name];
    [frq setPredicate: p];
    
    NSArray * arr = [[self managedObjectContext] executeFetchRequest: frq error: nil];
    BOOL dupe = NO;
    for (Bookmark *b in arr) {
        if (b == self) continue;
        dupe = YES;
        break;
    }
    if (dupe && outError) {
        NSDictionary *dict = @{ NSLocalizedFailureReasonErrorKey: @"duplicate name",
                                NSLocalizedDescriptionKey: @"duplicate name",
                                NSValidationKeyErrorKey: @"name",
                                NSValidationValueErrorKey: name,
                                NSValidationObjectErrorKey: self
        };
        NSError *e = [NSError errorWithDomain: @"Ample" code: 1 userInfo: dict];
        
        if (*outError) {
            *outError = [self errorFromOriginalError: *outError error: e];
        } else {
            *outError = e;
        }
    }
    return !dupe;
}


@end
