//
//  Wren.h
//  Wren
//
//  Created by Lucas Pereira on 20/05/15.
//  Copyright (c) 2015 Lucas Pereira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol WrenDelegate <NSObject>

//

@end

@interface Wren : NSObject

@property (unsafe_unretained) id<WrenDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)setAuthToken:(NSString *)token;
- (void)startGeoPushService;
- (void)startBeaconsService;
- (void)requestDefaultNotificationPermission;
- (void)didAllowPushNotifications:(BOOL)allowed withToken:(NSData *)pushToken;

@end
