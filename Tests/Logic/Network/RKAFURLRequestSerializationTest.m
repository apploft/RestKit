// AFHTTPRequestSerializationTests.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Taken and adapted from https://github.com/AFNetworking/AFNetworking/blob/master/Tests/Tests/AFHTTPRequestSerializationTests.m


#import "RKTestEnvironment.h"
#import "RKAFURLRequestSerialization.h"

@interface RKAFMultipartBodyStream : NSInputStream <NSStreamDelegate>
@property (readwrite, nonatomic, strong) NSMutableArray *HTTPBodyParts;
@end

@protocol AFMultipartFormDataTest <RKAFMultipartFormData>
@property (readwrite, nonatomic, strong) RKAFMultipartBodyStream *bodyStream;

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;
@end



@interface RKAFHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, copy) NSString *boundary;
@property (nonatomic, strong) id body;
@property (nonatomic, assign) NSUInteger bodyContentLength;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;
@property (readonly, nonatomic, assign, getter = hasBytesAvailable) BOOL bytesAvailable;
@property (readonly, nonatomic, assign) NSUInteger contentLength;

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length;
@end


@interface RKAFURLRequestSerializationTest : RKTestCase
@property (nonatomic, strong) RKAFHTTPRequestSerializer *requestSerializer;
@end


@implementation RKAFURLRequestSerializationTest

- (void)setUp {
    [super setUp];
    
    self.requestSerializer = [RKAFHTTPRequestSerializer serializer];
}

-(void)testThatRKAFHTTPRequestSerializationSerializesPOSTRequestProperly {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    request.HTTPMethod = @"POST";
    
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:request withParameters:@{@"key":@"value"} error:nil];
    NSString *contentType = serializedRequest.allHTTPHeaderFields[@"Content-Type"];
    
    assertThat(contentType, isNot(equalTo(nil)));
    assertThat(contentType, equalTo(@"application/x-www-form-urlencoded"));
    
    assertThat(serializedRequest.HTTPBody, isNot(equalTo(nil)));
    assertThat(serializedRequest.HTTPBody, equalTo([@"key=value" dataUsingEncoding:NSUTF8StringEncoding]));
}

- (void)testThatAFHTTPRequestSerializationSerializesPOSTRequestsProperlyWhenNoParameterIsProvided {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    request.HTTPMethod = @"POST";
    
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:request withParameters:nil error:nil];
    NSString *contentType = serializedRequest.allHTTPHeaderFields[@"Content-Type"];
    
    assertThat(contentType, isNot(equalTo(nil)));
    assertThat(contentType, equalTo(@"application/x-www-form-urlencoded"));
    
    assertThat(serializedRequest.HTTPBody, isNot(equalTo(nil)));
    assertThat(serializedRequest.HTTPBody, equalTo([NSData data]));
}

- (void)testThatAFHTTPRequestSerialiationSerializesQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"value"} error:nil];
    
    assertThat([[serializedRequest URL] query], equalTo(@"key=value"));
}



- (void)testThatEmptyDictionaryParametersAreProperlyEncoded {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{} error:nil];
    assertThatBool([serializedRequest.URL.absoluteString hasSuffix:@"?"], is(equalToBool(NO)));
}


- (void)testThatAFHTTPRequestSerialiationSerializesURLEncodableQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@" :#[]@!$&'()*+,;=/?"} error:nil];
    
    assertThat([[serializedRequest URL] query], equalTo(@"key=%20%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D/?"));
}

- (void)testThatAFHTTPRequestSerialiationSerializesURLEncodedQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"} error:nil];
    
    assertThat([[serializedRequest URL] query], equalTo(@"key=%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F"));
}

- (void)testThatAFHTTPRequestSerialiationSerializesQueryParametersCorrectlyFromQuerySerializationBlock {
    [self.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        __block NSMutableString *query = [NSMutableString stringWithString:@""];
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [query appendFormat:@"%@**%@",key,obj];
        }];
        
        return query;
    }];
    
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"value"} error:nil];
    assertThat([[serializedRequest URL] query], equalTo(@"key**value"));
}


- (void)testThatAFHTTPRequestSerialiationSerializesMIMETypeCorrectly {
    NSMutableURLRequest *originalRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    Class streamClass = NSClassFromString(@"RKAFStreamingMultipartFormData");
    id <AFMultipartFormDataTest> formData = [[streamClass alloc] initWithURLRequest:originalRequest stringEncoding:NSUTF8StringEncoding];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"adn_0" ofType:@"cer"]];
    
    [formData appendPartWithFileURL:fileURL name:@"test" error:NULL];
    
    RKAFHTTPBodyPart *part = [formData.bodyStream.HTTPBodyParts firstObject];
    
    assertThat(part.headers[@"Content-Type"], equalTo(@"application/x-x509-ca-cert"));
}

#pragma mark -

- (void)testThatValueForHTTPHeaderFieldReturnsSetValue {
    [self.requestSerializer setValue:@"Actual Value" forHTTPHeaderField:@"Set-Header"];
    NSString *value = [self.requestSerializer valueForHTTPHeaderField:@"Set-Header"];
    assertThat(value, equalTo(@"Actual Value"));
}

- (void)testThatValueForHTTPHeaderFieldReturnsNilForUnsetHeader {
    NSString *value = [self.requestSerializer valueForHTTPHeaderField:@"Unset-Header"];
    assertThat(value, is(equalTo(nil)));
}

- (void)testQueryStringSerializationCanFailWithError {
    RKAFHTTPRequestSerializer *serializer = [RKAFHTTPRequestSerializer serializer];
    
    NSError *serializerError = [NSError errorWithDomain:@"TestDomain" code:0 userInfo:nil];
    
    [serializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        *error = serializerError;
        return nil;
    }];
    
    NSError *error;
    NSURLRequest *request = [serializer requestWithMethod:@"GET" URLString:@"url" parameters:@{} error:&error];
    assertThat(request, is(equalTo(nil)));
    assertThat(error, is(equalTo(serializerError)));
}

- (void)testThatHTTPHeaderValueCanBeRemoved {
    RKAFHTTPRequestSerializer *serializer = [RKAFHTTPRequestSerializer serializer];
    NSString *headerField = @"TestHeader";
    NSString *headerValue = @"test";
    [serializer setValue:headerValue forHTTPHeaderField:headerField];
    
    assertThat(serializer.HTTPRequestHeaders[headerField], equalTo(headerValue));
    
    [serializer setValue:nil forHTTPHeaderField:headerField];
    assertThatBool([serializer.HTTPRequestHeaders.allKeys containsObject:headerField], is(equalToBool(NO)));
}

#pragma mark - Helper Methods

- (void)testQueryStringFromParameters {
    assertThat(RKAFQueryStringFromParameters(@{@"key":@"value",@"key1":@"value&"}), equalTo(@"key=value&key1=value%26"));
}

- (void)testPercentEscapingString {
    assertThat(RKAFPercentEscapedStringFromString(@":#[]@!$&'()*+,;=?/"), equalTo(@"%3A%23%5B%5D%40%21%24%26%27%28%29%2A%2B%2C%3B%3D?/"));
}

#pragma mark - #3028 tests
//https://github.com/AFNetworking/AFNetworking/pull/3028

- (void)testThatEmojiIsProperlyEncoded {
    //Start with an odd number of characters so we can cross the 50 character boundry
    NSMutableString *parameter = [NSMutableString stringWithString:@"!"];
    while (parameter.length < 50) {
        [parameter appendString:@"👴🏿👷🏻👮🏽"];
    }
    
    RKAFHTTPRequestSerializer *serializer = [RKAFHTTPRequestSerializer serializer];
    NSURLRequest *request = [serializer requestWithMethod:@"GET"
                                                URLString:@"http://test.com"
                                               parameters:@{@"test":parameter}
                                                    error:nil];
    assertThat(request.URL.query, equalTo(@"test=%21%F0%9F%91%B4%F0%9F%8F%BF%F0%9F%91%B7%F0%9F%8F%BB%F0%9F%91%AE%F0%9F%8F%BD%F0%9F%91%B4%F0%9F%8F%BF%F0%9F%91%B7%F0%9F%8F%BB%F0%9F%91%AE%F0%9F%8F%BD%F0%9F%91%B4%F0%9F%8F%BF%F0%9F%91%B7%F0%9F%8F%BB%F0%9F%91%AE%F0%9F%8F%BD%F0%9F%91%B4%F0%9F%8F%BF%F0%9F%91%B7%F0%9F%8F%BB%F0%9F%91%AE%F0%9F%8F%BD%F0%9F%91%B4%F0%9F%8F%BF%F0%9F%91%B7%F0%9F%8F%BB%F0%9F%91%AE%F0%9F%8F%BD"));
}

@end
