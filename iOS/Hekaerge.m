//
//  Hekaerge.m v2.0.0
//  MocaApp
//
//  Created by Iván González on 8/1/16.
//  Copyright © 2016 InnoQuant. All rights reserved.
//

#import "Hekaerge.h"
#import "HekaergeLocation.h"
#import "MOCA.h"
#import "MOCAProximityDelegate.h"

@import CoreBluetooth;


@interface Hekaerge() <MOCAProximityEventsDelegate, CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (assign, nonatomic) CBCentralManagerState bleStatus;
@property (strong, nonatomic) NSMutableArray<HekaergeLocation *> *lastOrderedLocations;
@property (strong, nonatomic) NSMutableArray<MOCABeacon *> *beaconsInRange;

@end

@implementation Hekaerge

- (instancetype)initWithLocations:(NSArray<HekaergeLocation *> *)locations
{
    NSParameterAssert(locations);
    if (self = [super init]) {
        _defaultLocations = [[NSArray alloc] initWithArray:locations];
        _lastOrderedLocations = nil;
    }
    _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
                                                             queue:nil
                                                           options:@{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:NO]}];

    //Ask MOCA for a beacon in range and sort Locations based on its geo coordinates.
    _bleStatus = _bluetoothManager ? _bluetoothManager.state : CBCentralManagerStateUnsupported;
    if (_bleStatus == CBCentralManagerStatePoweredOn) {
        [self orderListForLocation:[self lastKnownLocationByBeacons]];
    }
    
    if ([MOCAProximityService class]) {
        [MOCA proximityService].eventsDelegate = self;
    }
    _beaconsInRange = [[NSMutableArray alloc] init];

    return self;
}

/* Sort 'lastOrderedLocations' by distance to a certain location.
 * @param location: Locations in the array will be sorted by distance to this parameter. (closer first)
 */
- (void)orderListForLocation:(HekaergeLocation *)location
{
    if (!location) {
        self.lastOrderedLocations = nil;
    }
    else {
        self.lastOrderedLocations = [[NSMutableArray alloc] initWithArray:[self.defaultLocations sortedArrayUsingComparator:^(HekaergeLocation* loc1, HekaergeLocation* loc2) {
            
            //Use CLLocation built in distance calculator
            CLLocation * currLoc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
            CLLocation * location1 = [[CLLocation alloc] initWithLatitude:loc1.latitude longitude:loc1.longitude];
            CLLocation * location2 = [[CLLocation alloc] initWithLatitude:loc2.latitude longitude:loc2.longitude];
            
            CLLocationDistance dist_a = [location1 distanceFromLocation:currLoc] - loc1.radius;
            CLLocationDistance dist_b = [location2 distanceFromLocation:currLoc] - loc2.radius;
            
            //Inside both geofences
            if (dist_a < 0 && dist_b < 0) {
                //Policy: if same floor, smaller geofence location first
                if (loc1.floor == loc2.floor) {
                    if (loc1.radius < loc2.radius) {
                        return NSOrderedAscending; //a is closer
                    }
                    else if (loc1.radius > loc2.radius) {
                        return NSOrderedDescending; //a is closer
                    }
                }
            }
            
            //Regular cases
            else if ( dist_a < dist_b ) {
                return NSOrderedAscending; //a is closer
            } else if ( dist_a > dist_b) {
                return NSOrderedDescending; //b is closer
            }
            
            
            //same GPS coordinate && radius but distinct floor
            if (location.floor == loc1.floor) {
                return NSOrderedAscending; //a is closer
            }
            else if (location.floor == loc2.floor) {
                return NSOrderedDescending; //b is closer
            }
            return NSOrderedSame;
        }]];
    }
    //after locations have been sorted, call the delegate
    [self callDelegate];
}

/**
 * Returns location of the first beacon found with a known position, or null if
 * there are not known beacons in proximity (or there are no Locations in the beacons).
 */
- (HekaergeLocation *)lastKnownLocationByBeacons
{
    NSArray *beacons = [[NSArray alloc] initWithArray:[[MOCA proximityService] beacons]];
    if (!beacons) {
        return nil;
    }
    HekaergeLocation *lastKnownLocation;
    for (MOCABeacon *b in beacons) {
        if (b.proximity != CLProximityUnknown && b.location) {
            if ([self addBeacon:b]) {
                int radius = 0; //immediate
                if (b.proximity == CLProximityFar) {
                    radius = 20;
                }
                else if (b.proximity == CLProximityNear) {
                    radius = 5;
                }
                lastKnownLocation = [[HekaergeLocation alloc] initWithId:b.identifier
                                                            withLocation:b.location.coordinate
                                                                   floor:[b.floor doubleValue]
                                                                  radius:radius];
                break;
            }
        }
    }
    return lastKnownLocation;
}

#pragma mark - API

/*
 * If bluetooth is on, and a beacon (with Location) is in range, the location list
 * will be sorted by beacon distance
 */
- (NSArray<HekaergeLocation *> *)orderedLocations
{
    if (self.bleStatus == CBCentralManagerStatePoweredOn) {
        return self.lastOrderedLocations;
    }
    return nil;

}

//--------------------------

#pragma mark - MOCAProximityEventsDelegate

//We do not track proximity changes for performance reasons.
//To be discussed.

- (void)proximityService:(MOCAProximityService *)service didEnterRange:(MOCABeacon *)beacon withProximity:(CLProximity)proximity
{
    if ([self addBeacon:beacon]) {
        self.beaconsInRange = [[NSMutableArray alloc]initWithArray:[self.beaconsInRange sortedArrayUsingComparator:^(MOCABeacon *beacon1, MOCABeacon *beacon2) {
            if (beacon1.proximity == 0 ^ beacon2.proximity == 0) {
                if (beacon1.proximity != 0) {
                    return NSOrderedAscending;
                }
                return NSOrderedDescending;
            }
            if (beacon1.proximity < beacon2.proximity) {
                return NSOrderedAscending; //1 is closer
            }
            if (beacon2.proximity < beacon1.proximity) {
                return NSOrderedDescending; //2 is closer
            }
            return NSOrderedSame;
        }]];
        
        [self orderListForLocation:[self hekaergeLocationForBeacon:self.beaconsInRange.firstObject]];
    }
}

- (void)proximityService:(MOCAProximityService *)service didExitRange:(MOCABeacon *)beacon
{
    for (MOCABeacon* b in self.beaconsInRange) {
        if (beacon.identifier == b.identifier) {
            [self.beaconsInRange removeObjectIdenticalTo:beacon];
            if (self.beaconsInRange.count == 0) {
                [self orderListForLocation:nil];
            }
            else {
                [self orderListForLocation:[self hekaergeLocationForBeacon:self.beaconsInRange.firstObject]];
            }
            return;
        }
    }
}

#pragma mark - Utils

- (HekaergeLocation *)hekaergeLocationForBeacon:(MOCABeacon *)beacon
{
    //SDK Backwards compatibility
    double flr = 0;
    if (![beacon.floor isKindOfClass:[NSNull class]]) {
        flr = [beacon.floor doubleValue];
    }
    CLLocationCoordinate2D beaconCoord = beacon.location.coordinate;
    return [[HekaergeLocation alloc] initWithId:beacon.identifier
                                   withLocation:beaconCoord
                                          floor:flr
                                         radius:0];
}

- (void)callDelegate
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(hekaerge:didChangeLocation:)]) {
        [self.delegate hekaerge:self didChangeLocation:self.lastOrderedLocations];
    }
}

- (BOOL)addBeacon:(MOCABeacon *)beacon
{
    if (beacon.location) {
        CLLocationCoordinate2D bLoc = beacon.location.coordinate;
        double lat = bLoc.latitude;
        double lon = bLoc.longitude;
        if (lon != 0 && lat != 0) {
            [self.beaconsInRange addObject:beacon];
            return YES;
        }
    }
    return NO;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /* CBCentralManagerStateResetting
     * CBCentralManagerStateUnsupported
     * CBCentralManagerStateUnauthorized
     * CBCentralManagerStatePoweredOff
     * CBCentralManagerStatePoweredOn
     */
    self.bleStatus = central.state;
}

@end
