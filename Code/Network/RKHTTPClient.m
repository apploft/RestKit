//
//  RKHTTPClient.m
//  RestKit
//
//  Created by Oli on 21/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKHTTPClient.h"
#import "RKHTTPRequestSerializer.h"
#import "RKHTTPResponseSerializer.h"
#import "RKHTTPJSONResponseSerializer.h"
#import "RKHTTPPropertyListResponseSerializer.h"
#import "RKMIMETypeSerialization.h"
#import "RKLog.h"
#import "RKErrors.h"
#import "RKHTTPUtilities.h"

@interface RKHTTPClient ()

@property (readwrite, nonatomic, strong) NSURL *baseURL;
@property (strong, nonatomic) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSMutableDictionary *defaultHeaders;

@end

@implementation RKHTTPClient

@synthesize
baseURL = _baseURL,
HTTPMethodsEncodingParametersInURI = _HTTPMethodsEncodingParametersInURI,
requestSerializer = _requestSerializer,
requestSerializerClass = _requestSerializerClass,
responseSerializerClass = _responseSerializerClass,
defaultHeaders = _defaultHeaders;

///-------------------------------
/// @name Initializers
///-------------------------------

+ (instancetype)client{
    return [[self alloc] initWithBaseURL:nil sessionConfiguration:nil];
}

+ (instancetype)clientWithBaseURL:(NSURL*)baseURL{
    return [[self alloc] initWithBaseURL:baseURL sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url{
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration{
    
    self = [super init];
    if(!self){
        return nil;
    }
    
    self.baseURL = url;
    self.sessionConfiguration = configuration;
    self.requestSerializer = [RKHTTPRequestSerializer serializer];
    self.defaultHeaders = [NSMutableDictionary new];
    
    // HTTP Method Definitions; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
    
    return self;
}

- (void)addDefaultHeader:(NSString *)header
                   value:(NSString *)value{
    
    if(!value){
        return;
    }
    
    NSMutableArray *headers;
    if(!self.defaultHeaders[header]){
        headers = [NSMutableArray new];
        self.defaultHeaders[header] = headers;
    }
    
    if(![headers containsObject:value]){
        [headers addObject:value];
    }
}

- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value{
    
    if(!value){
        [self.defaultHeaders removeObjectForKey:header];
        return;
    }
    
    //Set the header to the new value
    self.defaultHeaders[header] = [NSMutableArray arrayWithObjects:value, nil];
}

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters{
    
    NSError *error;
    NSURL *url = [self URLStringByAppendingPath:path];
    NSString *URLString = [url absoluteString];
    
    //Construct an NSMutableURLRequest
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = method;
    request.URL = url;
    
    //Set default HTTP headers in the request
    [self.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id values, BOOL * __unused stop) {
        
        for(NSString *value in values){
            [request addValue:value forHTTPHeaderField:field];
        }
    }];
    
    //Detect the request mime type and default ot JSON if not set
    NSString *MIMEType = [request valueForHTTPHeaderField:@"Content-Type"];
    if(!MIMEType){
        MIMEType = RKMIMETypeJSON;
        [request setValue:MIMEType forHTTPHeaderField:@"Content-Type"];
    }
    
    //If no parameters, return request as-is
    if(!parameters){
        return request;
    }
    
    //Are we parameterizing the querystring or the HTTP Body
    if([self.HTTPMethodsEncodingParametersInURI containsObject:[method uppercaseString]]){
        
        BOOL hasQueryString     = url.query ? YES : NO;
        NSData *queryStringData = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
        NSString *queryString   = [[NSString alloc] initWithData:queryStringData encoding:NSUTF8StringEncoding];
        
        URLString               = [NSString stringWithFormat:hasQueryString ? @"%@&%@" : @"%@?%@", URLString, queryString];
        request.URL             = [NSURL URLWithString:URLString];
        
        //Else encode body with serializer
    }else{
        if(self.requestSerializerClass){
            request.HTTPBody = [self.requestSerializerClass dataFromObject: parameters error: &error];
        }else{
            request.HTTPBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:MIMEType error:&error];
        }
    }
    
    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <RKMultipartFormData> formData))block{
    
    NSError *error;
    
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:method
                                                                                URLString:[[self URLStringByAppendingPath: path] absoluteString]
                                                                               parameters:parameters
                                                                constructingBodyWithBlock:block
                                                                                    error:&error];
    
    if(error){
        NSLog(@"%@", error.localizedDescription);
    }
    
    return request;
    
}

-(NSURL*)URLStringByAppendingPath:(NSString*)path{
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:NO];
    components.path = [components.path stringByAppendingString:path];
    
    return [components URL];
}

- (NSURLSessionDataTask*)performRequest:(NSURLRequest *)request
                      completionHandler:(void (^)(id responseObject, NSData *responseData, NSURLResponse *response, NSError *error))completionHandler{
    
    NSURLSession *session = (self.sessionConfiguration ? [NSURLSession sessionWithConfiguration:self.sessionConfiguration] : [NSURLSession sharedSession]);
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(!completionHandler){
            return;
        }
        
        if(error){
            completionHandler(nil, nil, nil, error);
            return;
        }
        
        id responseObject;
        if(data.length) {
            if(self.responseSerializerClass){
                responseObject = [self.responseSerializerClass objectFromData:data error:&error];
            }else if (response.MIMEType) {
                responseObject = [RKMIMETypeSerialization objectFromData:data MIMEType:response.MIMEType error:&error];
            }
            
            if(!responseObject) {
                RKLogWarning(@"Unable to serialise data with error %@", error);
                responseObject = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                if(responseObject) error = nil;
            }
        }
        
        completionHandler(responseObject, data, response, error);
    }];
    
    [task resume];
    
    return task;
}

@end
