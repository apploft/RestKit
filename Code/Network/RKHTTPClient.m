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

@interface RKHTTPClient ()

@property (readwrite, nonatomic, strong) NSURL *baseURL;
@property (strong, nonatomic) NSURLSessionConfiguration *sessionConfiguration;

@end

@implementation RKHTTPClient

@synthesize
baseURL = _baseURL,
requestSerializer = _requestSerializer,
responseSerializerClass = _responseSerializerClass,
defaultCredential = _defaultCredential,
allowsInvalidSSLCertificate = _allowsInvalidSSLCertificate,
defaultSSLPinningMode = _defaultSSLPinningMode,
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
    
    return self;
}

- (void)setDefaultHeader:(NSString *)header
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

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters{
    
    NSError *error;
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method
                                                                   URLString:[self URLStringByAppendingPath: path]
                                                                  parameters:parameters
                                                                       error:&error];;
    if(error){
        NSLog(@"%@", error.localizedDescription);
    }
    
    for(NSString *key in self.defaultHeaders){
        NSArray *values = self.defaultHeaders[key];
        
        for(NSString *value in values){
            [request addValue:value forHTTPHeaderField:key];
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
                                                                                URLString:[self URLStringByAppendingPath: path]
                                                                               parameters:parameters
                                                                constructingBodyWithBlock:block
                                                                                    error:&error];
    
    if(error){
        NSLog(@"%@", error.localizedDescription);
    }
    
    return request;
    
}

-(NSString*)URLStringByAppendingPath:(NSString*)path{
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.baseURL resolvingAgainstBaseURL:NO];
    components.path = [components.path stringByAppendingString:path];
    
    return [components string];
}

- (NSURLSessionDataTask*)performRequest:(NSURLRequest *)request completionHandler:(void (^)(id responseObject, NSData *responseData, NSURLResponse *response, NSError *error))completionHandler{
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(completionHandler){
            
            id responseObject;
            if(self.responseSerializerClass){
                responseObject = [self.responseSerializerClass objectFromData:data error:&error];
            }else{
                responseObject = [RKMIMETypeSerialization objectFromData:data MIMEType:response.MIMEType error:&error];
            }
            
            completionHandler(responseObject, data, response, error);
        }
    }];
    
    [task resume];

    return task;
}

@end
