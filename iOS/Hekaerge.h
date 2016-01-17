//
//  Hekaerge.h
//  MocaApp
//
//  Created by Iván González on 8/1/16.
//  Copyright © 2016 InnoQuant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOCAProximityDelegate.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface HekaergeLocation : NSObject

@property (readonly) NSString * identifier;
@property (readonly) CLLocationCoordinate2D center;
@property (readonly) int floor;
@property (readonly) double latitude;
@property (readonly) double longitude;
@property (readonly) double radius;



-(instancetype)initWithId:(NSString*)identifier
             withLocation:(CLLocationCoordinate2D)center
                    floor:(int)floor
                   radius:(double)radius;

-(instancetype)initWithId:(NSString*)identifier
                 latitude:(double)latitude
                longitide:(double)longitude
                    floor:(int)floor
                   radius:(double)radius;
@end

@protocol HekaergeDelegate <NSObject>

- (void) didChangeLocation: (NSArray*) locations;

@end

@interface Hekaerge : NSObject <MOCAProximityEventsDelegate, CBCentralManagerDelegate>

@property id<HekaergeDelegate> delegate;

- (instancetype)initWithLocations: (NSArray<CLLocation *> *) locations;
- (NSArray * ) getOrderedLocations;
- (NSArray *) getDefaultLocations;

@end
