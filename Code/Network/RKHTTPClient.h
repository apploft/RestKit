//
//  RKHTTPClient.h
//  RestKit
//
//  Created by Oli on 12/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKHTTPRequestSerialization.h"
#import "RKSerialization.h"
#import "RKHTTP.h"

@protocol RKHTTPClient <NSObject>

/**
 The URL used to construct requests from relative paths in methods like `requestWithMethod:URLString:parameters:`, and the `GET` / `POST` / et al. convenience methods.
 */
@property (readonly, nonatomic, strong) NSURL *baseURL;

/**
 HTTP methods for which serialized requests will encode parameters as a query string. `GET`, `HEAD`, and `DELETE` by default.
 */
@property (nonatomic, strong) NSSet *HTTPMethodsEncodingParametersInURI;

/**
 Requests created with `multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:` are constructed with a set of default headers using a parameter serialization specified by this property. By default, this is set to an instance of `RKHTTPRequestSerializer`, which serializes query string parameters for `GET`, `HEAD`, and `DELETE` requests, or otherwise URL-form-encodes HTTP message bodies.
 
 @warning `requestSerializer` must not be `nil`.
 */
//@TODO: This is still needed for multipart uploads, we need to refactor this out to not depend on AFN
@property (nonatomic) id <RKHTTPRequestSerialization> requestSerializer;

/**
 Requests created with `requestWithMethod:URLString:parameters:` are constructed with a set of default headers using a parameter serialization specified by this property. By default, this serializes query string parameters for `GET`, `HEAD`, and `DELETE` requests, or otherwise uses this class if specified or selects an appropriate serializer from RKMIMETypeSerialization:dataFromObject:mimeType.
 Custom serializers can be registered with RKMIMETypeSerialization using RKMIMETYpeSerialization:registerClass:formMIMEType.
 */
@property (nonatomic) Class <RKSerialization> requestSerializerClass;

/**
 Responses from the server are passed through this class using RKSerialization:objectFromData:MIMEType to convert from string to an object.
 RKMIMETypeSerialization selects an appropriate serializer from RKMIMETypeSerialization:dataFromObject:mimeType, or uses this class if specified.
 Custom serializers can be registered with RKMIMETypeSerialization using RKMIMETYpeSerialization:registerClass:formMIMEType.
 */
@property (nonatomic) Class <RKSerialization> responseSerializerClass;

/**
 The default HTTP headers used 
 **/
@property (readonly, nonatomic, strong) NSDictionary *defaultHeaders;

/**
 Creates and returns an `RKHTTPClient` object.
 */
+ (instancetype)client;

/**
 Static Initializer
 **/
+ (instancetype)clientWithBaseURL:(NSURL*)baseURL;

/**
 Initializes an `RKHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url;

/**
 Initializes an `AFHTTPSessionManager` object with the specified base URL.
 
 This is the designated initializer.
 
 @param url The base URL for the HTTP client.
 @param configuration The configuration used to create the managed session.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.
 
 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path.
 
 If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If `nil`, no path will be appended to the base URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2
 
 Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.
 
 @param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `RKMultipartFormData` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <RKMultipartFormData> formData))block;


/**
 Performs and HTTP request using the supplied request object.
 @param request A NSURLRequest object that represents the request being made
 @param completionHandler A callback block on completion of the request. Block parameters represent the unserialized response object, the NSURLResponse and any associated error
 */
- (NSURLSessionDataTask*)performRequest:(NSURLRequest *)request
                      completionHandler:(void (^)(id responseObject, NSData *responseData, NSURLResponse *response, NSError *error))completionHandler;

@end


@interface RKHTTPClient : NSObject <RKHTTPClient>

@property (strong, nonatomic, readonly) NSURLSession *session;

@end
