//
//  Transformers.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Transformers.h"

@implementation FilePathTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) return value;
    
    return [(NSString *)value lastPathComponent];
}

@end

@implementation FileSizeTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) return value;
    if (![value respondsToSelector: @selector(integerValue)]) {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -integerValue.",
        [value class]];
    }
    NSInteger size = [(NSNumber *)value integerValue];

    if (size < 0) return nil;
    if (size < 1024*1024) return [NSString stringWithFormat: @"%.1fKB", (float)size / 1024];
    if (size < 1024*1024*1024) return [NSString stringWithFormat: @"%.1fMB", (float)size / (1024*1024)];

    return [NSString stringWithFormat: @"%.1fGB", (float)size / (1024*1024*1024)];
}

@end



void RegisterTransformers(void) {
    
    NSValueTransformer *t;
    t = [FileSizeTransformer new];
    [NSValueTransformer setValueTransformer: t forName: @"FileSizeTransformer"];

    t = [FilePathTransformer new];
    [NSValueTransformer setValueTransformer: t forName: @"FilePathTransformer"];

}
