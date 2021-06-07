//
//  Transformers.h
//  Ample
//
//  Created by Kelvin Sherlock on 9/13/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>

void RegisterTransformers(void);

NS_ASSUME_NONNULL_BEGIN

@interface FilePathTransformer : NSValueTransformer
@end

@interface FileSizeTransformer : NSValueTransformer
@end

@interface ValidColorTransformer : NSValueTransformer
@end

@interface StringNotEmptyTransformer : NSValueTransformer
@end


NS_ASSUME_NONNULL_END
