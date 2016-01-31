//
//  HekaergeLocation.h
//  test
//
//  Created by Luis Valdés on 31/1/16.
//  Copyright © 2016 Luis Valdés. All rights reserved.
//

@import Foundation;
@import CoreLocation;

@interface HekaergeLocation : NSObject

@property (nonatomic, readonly) NSString * identifier;
@property (nonatomic, readonly) CLLocationCoordinate2D center;
@property (nonatomic, readonly) int floor;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) double radius;

- (instancetype)initWithId:(NSString *)identifier
              withLocation:(CLLocationCoordinate2D)center
                     floor:(int)floor
                    radius:(double)radius;

- (instancetype)initWithId:(NSString *)identifier
                  latitude:(double)latitude
                 longitude:(double)longitude
                     floor:(int)floor
                    radius:(double)radius;

@end
