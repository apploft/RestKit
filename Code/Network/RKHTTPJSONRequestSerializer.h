//
//  RKHTTPJSONRequestSerialization.h
//  RestKit
//
//  Created by Oli on 12/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKHTTPRequestSerialization.h"
#import "RKAFURLRequestSerialization.h"

@protocol RKHTTPJSONRequestSerialization <RKHTTPRequestSerialization>

/**
 Options for writing the request JSON data from Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONWritingOptions". `0` by default.
 */
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

/**
 Creates and returns a JSON serializer with specified reading and writing options.
 
 @param writingOptions The specified JSON writing options.
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;

@end


@interface RKHTTPJSONRequestSerializer : RKAFJSONRequestSerializer <RKHTTPJSONRequestSerialization>

@end
