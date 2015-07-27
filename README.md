# README #

* The Wren class is a very straightforward singleton.
* You simply set its *AuthToken*
* Start the services of GeoPushNotifications and/or Beacons
* Implement the methods in the AppDelegate as described:


```
#!objective-c

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[Wren sharedInstance]didAllowPushNotifications:NO withToken:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Wren sharedInstance]didAllowPushNotifications:YES withToken:deviceToken];
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}
```


### What is this repository for? ###

* This is a simple objC library for integrating with WrenSys Api

### Setup ###

This library requires two other libraries for properly working:

```
#!objective-c

* AFNetworking
* iAppInfos
```

I recommend using the CocoaPod spec:
```
pod "AFNetworking", "~> 2.0"
pod "iAppInfos"
```

### Generating the .Framework file ###

For building the framework you simple have to clone and build the project. It already has a building script that will generate the .framework file and save it to your **Desktop**