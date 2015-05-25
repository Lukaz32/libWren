//
//  WSUrl.m
//  Wren
//
//  Created by Lucas Pereira on 21/05/15.
//  Copyright (c) 2015 Lucas Pereira. All rights reserved.
//

#import "WSUrl.h"

@implementation WSUrl

- (NSString *)baseURLString {
    return @"http://api.wrensys.com/api/v1/";
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:[self baseURLString]];
}

- (NSURL *)registerDevice {
    return [NSURL URLWithString:[[self baseURLString]stringByAppendingString:@"device"]];
}



@end
