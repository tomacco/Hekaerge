//
//  HekaergeLocation.m
//  test
//
//  Created by Luis Valdés on 31/1/16.
//  Copyright © 2016 Luis Valdés. All rights reserved.
//

#import "HekaergeLocation.h"

@implementation HekaergeLocation

- (instancetype)initWithId:(NSString *)identifier
              withLocation:(CLLocationCoordinate2D)center
                     floor:(int)floor
                    radius:(double)radius
{
    NSParameterAssert(identifier);
    if (self = [super init]) {
        _identifier = identifier;
        _center = center;
        _floor = floor;
        _latitude = center.latitude;
        _longitude = center.longitude;
        _radius = radius;
    }
    return self;
}

- (instancetype)initWithId:(NSString *)identifier
                  latitude:(double)latitude
                 longitude:(double)longitude
                     floor:(int)floor
                    radius:(double)radius
{
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return [self initWithId:identifier withLocation:center floor:floor radius:radius];
}

- (BOOL)isEqualToHekaergeLocation:(HekaergeLocation *)other
{
    if (other == self) {
        return YES;
    }
    return (other.latitude   == self.latitude &&
            other.longitude  == self.latitude &&
            other.floor      == self.floor &&
            other.radius     == self.radius);
}

@end
