//
//  Wren.m
//  Wren
//
//  Created by Lucas Pereira on 20/05/15.
//  Copyright (c) 2015 Lucas Pereira. All rights reserved.
//

#import "Wren.h"
#import <CoreLocation/CoreLocation.h>
#import "WSManager.h"
#import "iBeacon.h"


NSString static *kCURRENTLY_MONITORED_BEACONS = @"kcurrentlymonitoredbeacons";

@interface Wren() <CLLocationManagerDelegate>
{
    UIBackgroundTaskIdentifier bgTask;
}

@property (nonatomic, strong) NSString *token;
@property (nonatomic, copy) void (^notificationPermissionCallback)(BOOL success);
@property (nonatomic, copy) void (^locationPermissionCallback)(BOOL success);
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *currentlyInsideRegion;


@end

@implementation Wren

+ (instancetype)sharedInstance
{
    static Wren *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Wren alloc] init];
    });
    return sharedInstance;
}

#pragma mark -
#pragma mark Public API

/**
 * Sets the Auth-Token to be used on the webservice requests
 *
 * @param token A string Auth-Token
 */
- (void)setAuthToken:(NSString *)token
{
    self.token = token;
}

/**
 * Registers the device if necessary.
 *
 * Asks for Push Notification permission if necessary.
 *
 * Asks for Location permission if necessary.
 *
 * If all of the above is allowed it starts monitoring for significant location changes.
 *
 * When noticing a location change grater than 500 meters, it sends the device's coordinates to the webservice.
 */
- (void)startGeoPushService
{
    [self deviceIsRegistered:^(BOOL isRegistered) {
        if (isRegistered)
        {
            [self requestNotificationPermissionRequestWithCompletion:^(BOOL success) {
                if (success)
                {
                    [self requestLocationPermissionWithCompletion:^(BOOL success) {
                        if (success)
                        {
                            [self.locationManager startMonitoringSignificantLocationChanges];
                        }
                    }];
                }
            }];
        }
    }];
}

/**
 * Registers the device if necessary.
 *
 * Asks for Location permission if necessary.
 *
 * If location is allowed it queries the webservice for a list of beacons and start monitoring for their regions.
 * When entering one of them, the webservice will be queried again for details of the region which will be displayed
 * as a UILocationNotification to the user.
 */
- (void)startBeaconsService
{
    [self deviceIsRegistered:^(BOOL isRegistered) {
        if (isRegistered) {
            [self requestLocationPermissionWithCompletion:^(BOOL success) {
                if (success) {
                    [[WSManager sharedManagerWithAuthToken:self.token]getAllBeaconsToBeMonitoredWithCompletionBlock:^(NSArray *beacons, NSError *error) {
                        if (!error && beacons) {
                            [self startMonitoringForBeacons:beacons];
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)requestDefaultNotificationPermission
{
    [self requestNotificationPermissionRequestWithCompletion:nil];
}

//Observer that gets the user response on notification permission
- (void)didAllowPushNotifications:(BOOL)allowed withToken:(NSData *)pushToken
{
    NSLog(@"[WREN] didAllowPushNotificationsWithToken: %@",pushToken);
    
    if (allowed && pushToken) {
        [[WSManager sharedManagerWithAuthToken:self.token]enablePushNotificationsWithToken:pushToken andCompletionBlock:^(NSError *error)
         {
             if (!error)
             {
                 NSLog(@"[WREN] Successfully enabled push notification on the webservice.");
                 if (self.notificationPermissionCallback) self.notificationPermissionCallback(YES);
             }else {
                 if (self.notificationPermissionCallback) self.notificationPermissionCallback(NO);
             }
         }];
    }
}

#pragma mark -
#pragma mark Private API

- (void)deviceIsRegistered:(void(^)(BOOL isRegistered))response
{
    [[WSManager sharedManagerWithAuthToken:self.token]registerDeviceWithCompletionBlock:^(NSError *error) {
        if (!error){
            response(YES);
        }else {
            response(NO);
        }
    }];
}

- (BOOL)notificationsAreEnabled
{
    //iOS 8+ API
    if ([[UIApplication sharedApplication]respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        return [[UIApplication sharedApplication]isRegisteredForRemoteNotifications];
    }
    //Older API
    UIRemoteNotificationType type = [[UIApplication sharedApplication]enabledRemoteNotificationTypes];
    
    if (type != UIRemoteNotificationTypeNone) {
        return NO;
    }
    
    return YES;
}

//BEACONS

- (void)startMonitoringForBeacons:(NSArray *)beacons
{
    //TODO: confirm whether this really works (remove while enumerating)
    for (CLBeaconRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    [[NSUserDefaults standardUserDefaults]setObject:@[] forKey:kCURRENTLY_MONITORED_BEACONS];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    for (NSDictionary *beaconDict in beacons) {
        NSUUID *proximityUUID = [[NSUUID alloc]initWithUUIDString:beaconDict[@"uuid"]];
        UInt16 major = [(NSString *)beaconDict[@"major"] intValue];
        UInt16 minor = [(NSString *)beaconDict[@"minor"] intValue];
        NSString *identifier = beaconDict[@"identifier"];
        
        CLBeaconRegion *region = [[CLBeaconRegion alloc]initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
        
        [self.locationManager startMonitoringForRegion:region];
        
        NSLog(@"[WREN] Started monitoring for region: %@, major: %@, minor: %@",region.proximityUUID.UUIDString,region.major, region.minor);
        
        NSMutableArray *currentBeacons = [[[NSUserDefaults standardUserDefaults]objectForKey:kCURRENTLY_MONITORED_BEACONS]mutableCopy];
        
        iBeacon *beacon = [iBeacon new];
        beacon.UUIDString = region.proximityUUID.UUIDString;
        beacon.major = region.major.stringValue;
        beacon.minor = region.minor.stringValue;
        beacon.offerTitle = beaconDict[@"title]"];
        beacon.offerDescription = beaconDict[@"description"];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:beacon];
        
        [currentBeacons addObject:data];
        [[NSUserDefaults standardUserDefaults]setObject:currentBeacons forKey:kCURRENTLY_MONITORED_BEACONS];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    
    NSLog(@"[WREN] Currently monitoring %lu regions",(unsigned long)self.locationManager.monitoredRegions.count);
}

- (void)didEnterRegion:(CLBeaconRegion *)region
{
    if (region != self.currentlyInsideRegion) {
        NSLog(@"[WREN] Entered region: %@",region.proximityUUID.UUIDString);
        self.currentlyInsideRegion = region;
        [self getDetailForRegion:region];
    }
}

- (void)getDetailForRegion:(CLBeaconRegion *)region
{
    if ([[UIApplication sharedApplication]applicationState] == UIApplicationStateActive) {
        UIApplication *app = [UIApplication sharedApplication];
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
        }];
    }
    
    NSLog(@"[WREN] Getting detail for region: %@",region.proximityUUID.UUIDString);
    
    [[WSManager sharedManagerWithAuthToken:self.token]getDetailForBeaconWithUUID:region.proximityUUID.UUIDString andCompletionBlock:^(NSDictionary *result, NSError *error) {
        if (!error) {
            UILocalNotification *couponNotification = [UILocalNotification new];
            couponNotification.alertBody = result[@"description"];
            couponNotification.userInfo = @{@"offerId":result[@"major"]};
            couponNotification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication]scheduleLocalNotification:couponNotification];
        }else
        {
            NSMutableArray *currentlyMonitoredBeacons = [[[NSUserDefaults standardUserDefaults]objectForKey:kCURRENTLY_MONITORED_BEACONS]mutableCopy];
            for (NSData *beaconData in currentlyMonitoredBeacons) {
                iBeacon *beacon = [NSKeyedUnarchiver unarchiveObjectWithData:beaconData];
                if ([beacon.UUIDString isEqualToString:region.proximityUUID.UUIDString]) {
                    UILocalNotification *couponNotification = [UILocalNotification new];
                    couponNotification.alertBody = [NSString stringWithFormat:@"%@: %@",beacon.offerTitle,beacon.offerDescription];
                    couponNotification.userInfo = @{@"offerId":beacon.major};
                    couponNotification.soundName = UILocalNotificationDefaultSoundName;
                    [[UIApplication sharedApplication]scheduleLocalNotification:couponNotification];
                }
            }
        }
    }];
}

//NOTIFICATIONS
- (void)requestNotificationPermissionRequestWithCompletion:(void(^)(BOOL success))completion
{
    //    if ([self notificationsAreEnabled])
    //    {
    //        completion(YES);
    //    }else
    //    {
    //Block for handling push permission callback from the AppDelegate
    self.notificationPermissionCallback = completion;
    
    //iOS 8+ API
    if ([[UIApplication sharedApplication]respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        
        UIUserNotificationType notifTypes = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        
        UIUserNotificationSettings *notifSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:nil];
        
        [[UIApplication sharedApplication]registerUserNotificationSettings:notifSettings];
    }
    else //Older API
    {
        UIRemoteNotificationType notifType = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication]registerForRemoteNotificationTypes:notifType];
    }
    //    }
}

//LOCATION
- (void)requestLocationPermissionWithCompletion:(void(^)(BOOL success))completion
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)
    {
        completion(YES);
    }
    else if ([CLLocationManager locationServicesEnabled])
    {
        self.locationPermissionCallback = completion;
        
        //iOS 8+ API
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        else
        {
            completion(YES);
        }
    }
    else
    {
        completion(NO);
    }
}

- (void)processLocationData:(CLLocation *)location
{
    //Send location data to the webservice
    [[WSManager sharedManagerWithAuthToken:self.token]updateLocation:location
                                                 withCompletionBlock:^(NSError *error) {
                                                     if (!error) {
                                                         //Location successfully sent
                                                     }
                                                 }];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString *msg = @"[WREN] didChangeAuthorizationStatus: ";
    switch (status) {
        case kCLAuthorizationStatusRestricted:
            if (self.locationPermissionCallback) self.locationPermissionCallback(NO);
            msg = [msg stringByAppendingString:@"kCLAuthorizationStatusRestricted"];
            break;
        case kCLAuthorizationStatusDenied:
            if (self.locationPermissionCallback) self.locationPermissionCallback(NO);
            msg = [msg stringByAppendingString:@"kCLAuthorizationStatusDenied"];
            break;
        case kCLAuthorizationStatusNotDetermined:
            if (self.locationPermissionCallback) self.locationPermissionCallback(NO);
            msg = [msg stringByAppendingString:@"kCLAuthorizationStatusNotDetermined"];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.locationPermissionCallback) self.locationPermissionCallback(YES);
            msg = [msg stringByAppendingString:@"kCLAuthorizationStatusAuthorizedAlways"];
            break;
        default:
            if (self.locationPermissionCallback) self.locationPermissionCallback(YES);
            msg = [msg stringByAppendingString:@"kCLAuthorizationStatusAuthorizedWhenInUse"];
            break;
    }
    
    NSLog(@"%@",msg);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //Get the most accurate location
    CLLocation *bestAccuracyLocation = locations[0];
    for (CLLocation *location in locations)
    {
        if (location.horizontalAccuracy < bestAccuracyLocation.horizontalAccuracy)
        {
            bestAccuracyLocation = location;
        }
    }
    
    [self processLocationData:bestAccuracyLocation];
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self didEnterRegion:(CLBeaconRegion *)region];
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateUnknown:
            self.currentlyInsideRegion = nil;
            break;
        case CLRegionStateInside:
            [self didEnterRegion:(CLBeaconRegion *)region];
            break;
        case CLRegionStateOutside:
            self.currentlyInsideRegion = nil;
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Lazy Instantiation

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 500;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return _locationManager;
}

@end
