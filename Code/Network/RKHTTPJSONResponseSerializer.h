//
//  RKHTTPJSONResponseSerialization.h
//  RestKit
//
//  Created by Oli on 12/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKHTTPResponseSerialization.h"
#import "RKAFURLResponseSerialization.h"

@protocol RKHTTPJSONResponseSerialization <RKHTTPResponseSerialization>

/**
 Options for reading the response JSON data and creating the Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONReadingOptions". `0` by default.
 */
@property (nonatomic, assign) NSJSONReadingOptions readingOptions;

/**
 Whether to remove keys with `NSNull` values from response JSON. Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL removesKeysWithNullValues;

/**
 Creates and returns a JSON serializer with specified reading and writing options.
 
 @param readingOptions The specified JSON reading options.
 */
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;

@end


@interface RKHTTPJSONResponseSerializer : RKAFJSONResponseSerializer <RKHTTPJSONResponseSerialization>

@end
