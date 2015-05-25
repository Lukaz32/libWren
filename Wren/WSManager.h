//
//  WSManager.h
//  Wren
//
//  Created by Lucas Pereira on 20/05/15.
//  Copyright (c) 2015 Lucas Pereira. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface WSManager : AFHTTPRequestOperationManager

+ (instancetype)sharedManagerWithAuthToken:(NSString *)authToken;
- (AFURLConnectionOperation *)registerDeviceWithCompletionBlock:( void (^)(NSError *error))completion;
- (AFURLConnectionOperation *)enablePushNotificationsWithToken:(NSData *)token andCompletionBlock:( void (^)(NSError *error))completion;
- (AFURLConnectionOperation *)disablePushNotificationsWithCompletionBlock:(void(^)(NSError *error))completion;
- (AFURLConnectionOperation *)updateLocation:(CLLocation *)location withCompletionBlock:(void(^)(NSError *error))completion;
- (AFURLConnectionOperation *)getAllBeaconsToBeMonitoredWithCompletionBlock:(void(^)(NSArray *beacons, NSError *error))completion;
- (AFURLConnectionOperation *)getDetailForBeaconWithUUID:(NSString *)UUIDString andCompletionBlock:(void(^)(NSDictionary *result, NSError *error))completion;

@end
