//
//  iBeacon.h
//  Receitas Zaffari
//
//  Created by Lucas Pereira on 19/05/15.
//  Copyright (c) 2015 Howmobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iBeacon : NSObject <NSCoding>

@property (nonatomic,strong) NSString *UUIDString;
@property (nonatomic,strong) NSString *identifier;
@property (nonatomic,strong) NSString *major;
@property (nonatomic,strong) NSString *minor;
@property (nonatomic,strong) NSString *offerTitle;
@property (nonatomic,strong) NSString *offerDescription;




@end
