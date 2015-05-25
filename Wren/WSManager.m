//
//  WSManager.m
//  Wren
//
//  Created by Lucas Pereira on 20/05/15.
//  Copyright (c) 2015 Lucas Pereira. All rights reserved.
//

#import "WSManager.h"
#import "WSUrl.h"
#import <iAppInfos/iAppInfos.h>



NSString static *kWSUDID = @"wsudid";
NSString static *kAuthToken = @"X-Auth-Token";

@interface WSManager ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation WSManager

+ (instancetype)sharedManagerWithAuthToken:(NSString *)authToken
{
    static WSManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [NSURL URLWithString:@"http://api.wrensys.com/"];
        _sharedClient = [[WSManager alloc] initWithBaseURL:baseURL];
        _sharedClient.requestSerializer = [AFJSONRequestSerializer serializer];
        _sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
        [_sharedClient.requestSerializer setValue:authToken forKey:kAuthToken];
    });
    
    return _sharedClient;
}
#pragma mark -
#pragma mark Register Device

- (AFURLConnectionOperation *)registerDeviceWithCompletionBlock:( void (^)(NSError *error))completion
{
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (!udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        NSString *manufacturer = @"Apple";
        NSString *model = [[iAppInfos sharedInfo]infoForKey:AppVersionManagerKeyYourDeviceModel];
        NSString *os = @"ios";
        NSString *osVersion = [[iAppInfos sharedInfo]infoForKey:AppVersionManagerKeyYouriOSVersion];
        NSString *appVersion = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        NSDictionary *parameters = @{@"manufacturer":manufacturer,
                                     @"model":model,
                                     @"os":os,
                                     @"os_version":osVersion,
                                     @"app_version":appVersion};
        
        __block WSManager *weakSelf = self;
        
        AFURLConnectionOperation *operation = [self POST:@"device"
                                              parameters:parameters
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     
                                                     if (operation.response.statusCode == 200) {
                                                         
                                                         NSDictionary *responseDict = responseObject;
                                                         if (responseDict[@"udid"])
                                                         {
                                                             [weakSelf.defaults setObject:responseDict[@"udid"] forKey:kWSUDID];
                                                             [weakSelf.defaults synchronize];
                                                             completion(nil);
                                                         }else {
                                                             completion([NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Register device failed."}]);
                                                         }
                                                     }else {
                                                         completion([NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Register device failed"}]);
                                                     }
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                     
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     completion(error);
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                 }];
        
        return operation;
    }else {
        completion(nil);
        return nil;
    }
}

#pragma mark -
#pragma mark Enable Push w/ Token

- (AFURLConnectionOperation *)enablePushNotificationsWithToken:(NSData *)token andCompletionBlock:( void (^)(NSError *error))completion
{
    #if !TARGET_IPHONE_SIMULATOR
    
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        NSString *tokenString = [[[tokenString.description stringByReplacingOccurrencesOfString:@">" withString:@" "]stringByReplacingOccurrencesOfString:@"<" withString:@" "]stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSDictionary *parameters = @{@"push_token":tokenString};
        
        AFURLConnectionOperation *operation = [self POST:[NSString stringWithFormat:@"device/%@/push",udid]
                                              parameters:parameters
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     
                                                     if (operation.response.statusCode == 200) {
                                                         
                                                         completion(nil);
                                                         
                                                     }else {
                                                         completion([NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Enable Push Notifications Failed."}]);
                                                     }
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                     
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     completion(error);
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                 }];
        
        return operation;
    }
    completion([NSError errorWithDomain:@"WSManager" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Enable Push Notifications Failed. No UDID found."}]);
    return nil;
    
    #endif
    return nil;
}

#pragma mark -
#pragma mark Disable Push

- (AFURLConnectionOperation *)disablePushNotificationsWithCompletionBlock:(void(^)(NSError *error))completion
{
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        AFURLConnectionOperation *operation = [self DELETE:[NSString stringWithFormat:@"device/%@/push",udid]
                                              parameters:nil
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     
                                                     if (operation.response.statusCode == 200) {
                                                         
                                                         completion(nil);
                                                         
                                                     }else {
                                                         completion([NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Disable Push Notifications Failed."}]);
                                                     }
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                     
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     completion(error);
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                 }];
        
        return operation;
    }
    completion([NSError errorWithDomain:@"WSManager" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Disable Push Notifications Failed. No UDID found."}]);
    return nil;
}

#pragma mark -
#pragma mark Update Location

- (AFURLConnectionOperation *)updateLocation:(CLLocation *)location withCompletionBlock:(void(^)(NSError *error))completion
{
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        NSDictionary *parameters = @{@"latitude":[NSNumber numberWithFloat:location.coordinate.latitude],
                                     @"longitude":[NSNumber numberWithFloat:location.coordinate.longitude]};
        
        AFURLConnectionOperation *operation = [self POST:[NSString stringWithFormat:@"device/%@/location",udid]
                                                parameters:parameters
                                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                       
                                                       if (operation.response.statusCode == 200 && [responseObject[@"message"]isEqualToString:@"Location Saved!"]) {
                                                           
                                                           completion(nil);
                                                           
                                                       }else {
                                                           completion([NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Update Location Failed."}]);
                                                       }
                                                       [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                       
                                                   }
                                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                       completion(error);
                                                       [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                   }];
        
        return operation;
    }
    completion([NSError errorWithDomain:@"WSManager" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Update Location Failed. No UDID found."}]);
    return nil;
}

#pragma mark -
#pragma mark Beacons

- (AFURLConnectionOperation *)getAllBeaconsToBeMonitoredWithCompletionBlock:(void(^)(NSArray *beacons, NSError *error))completion
{
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        AFURLConnectionOperation *operation = [self POST:@"beacons"
                                              parameters:nil
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     
                                                     if (operation.response.statusCode == 200) {
                                                         
                                                         completion(responseObject,nil);
                                                         
                                                     }else {
                                                         completion(nil,[NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Get All Beacons Failed."}]);
                                                     }
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                     
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     completion(nil,error);
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                 }];
        
        return operation;
    }
    completion(nil,[NSError errorWithDomain:@"WSManager" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Get All Beacons Failed. No UDID found."}]);
    return nil;
}

- (AFURLConnectionOperation *)getDetailForBeaconWithUUID:(NSString *)UUIDString andCompletionBlock:(void(^)(NSDictionary *result, NSError *error))completion
{
    NSString *udid = [self.defaults objectForKey:kWSUDID];
    
    if (udid)
    {
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
        
        AFURLConnectionOperation *operation = [self POST:[NSString stringWithFormat:@"beacons/%@",UUIDString]
                                              parameters:nil
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     
                                                     if (operation.response.statusCode == 200) {
                                                         
                                                         completion(responseObject,nil);
                                                         
                                                     }else {
                                                         completion(nil,[NSError errorWithDomain:@"WSManager" code:operation.response.statusCode userInfo:@{NSLocalizedDescriptionKey:@"Get Detail for Beacon Failed."}]);
                                                     }
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                     
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     completion(nil,error);
                                                     [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                                                 }];
        
        return operation;
    }
    completion(nil,[NSError errorWithDomain:@"WSManager" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Get Detail for Beacon Failed. No UDID found."}]);
    return nil;
}

#pragma mark -
#pragma mark Lazy Instantiation

- (NSUserDefaults *)defaults {
    if (!_defaults) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

@end
