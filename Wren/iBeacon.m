//
//  iBeacon.m
//  Receitas Zaffari
//
//  Created by Lucas Pereira on 19/05/15.
//  Copyright (c) 2015 Howmobile. All rights reserved.
//

#import "iBeacon.h"

@implementation iBeacon

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.UUIDString = [decoder decodeObjectForKey:@"UUIDString"];
    self.identifier = [decoder decodeObjectForKey:@"identifier"];
    self.major = [decoder decodeObjectForKey:@"major"];
    self.minor = [decoder decodeObjectForKey:@"minor"];
    self.offerTitle = [decoder decodeObjectForKey:@"offerTitle"];
    self.offerDescription = [decoder decodeObjectForKey:@"offerDescription"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.UUIDString forKey:@"UUIDString"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.major forKey:@"major"];
    [encoder encodeObject:self.minor forKey:@"minor"];
    [encoder encodeObject:self.offerTitle forKey:@"offerTitle"];
    [encoder encodeObject:self.offerDescription forKey:@"offerDescription"];
}

@end
