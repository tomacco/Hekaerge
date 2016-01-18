//
//  Hekaerge.m v1.0.2
//  MocaApp
//
//  Created by Iván González on 8/1/16.
//  Copyright © 2016 InnoQuant. All rights reserved.
//

#import "Hekaerge.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MOCA.h"


@implementation HekaergeLocation

@synthesize identifier=_identifier, center=_center, floor = _floor, latitude = _latitude, longitude = _longitude, radius = _radius  ;

-(instancetype)initWithId:(NSString*)identifier
             withLocation:(CLLocationCoordinate2D)center
                    floor:(int)floor
                   radius:(double)radius
{
    NSParameterAssert(identifier);
    
    self = [super init];
    if (self) {
        _identifier = identifier;
        _center = center;
        _floor = floor;
        _latitude = center.latitude;
        _longitude = center.longitude;
        _radius = radius;
    }
    return self;
}

-(instancetype)initWithId:(NSString*)identifier
                 latitude:(double)latitude
                longitide:(double)longitude
                    floor:(int)floor
                   radius:(double)radius
{
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return [self initWithId:identifier withLocation:center floor:floor radius:radius];
}

-(BOOL) isEqualToHekaergeLocation:(HekaergeLocation*)other
{
    if(other == self)
        return YES;
    if(
       other.latitude   == self.latitude &&
       other.longitude  == self.latitude &&
       other.floor      == self.floor &&
       other.radius     == self.radius)
    {
        return YES;
    }
    return NO;
}

@end

//
// -------------------------------------------------------------------------------------
//

@interface Hekaerge()
{
    CBCentralManager                * _bluetoothManager;
    CBCentralManagerState           _bleStatus;
    NSMutableArray                  * _lastOrderedLocations;
    NSArray                         * _defaultLocations;
    NSMutableArray<MOCABeacon*>     * _beaconsInRange;
}
@end

@implementation Hekaerge

@synthesize delegate = _delegate;


- (instancetype)initWithLocations: (NSArray<HekaergeLocation *> *) locations
{
    NSParameterAssert(locations);
    self = [super init];
    if(self){
        _defaultLocations = [[NSArray alloc] initWithArray:locations];
        _lastOrderedLocations = [[NSMutableArray alloc] initWithArray: locations];
    }
    _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil
                                                  options:@{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:NO]}];

    //Ask MOCA for a beacon in range and sort Locations based on its geo coordinates.
    if(_bluetoothManager != nil){
        _bleStatus = _bluetoothManager.state;
        if(_bleStatus == CBCentralManagerStatePoweredOn){
            [self orderListForLocation:[self getLastKnownLocationByBeacons]];
        }
    }
    else{
        _bleStatus = CBCentralManagerStateUnsupported;
    }
    if([MOCAProximityService class]){
        [MOCA proximityService].eventsDelegate = self;
    }
    _beaconsInRange = [[NSMutableArray alloc] init];

    return self;
}

- (id<HekaergeDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<HekaergeDelegate>)newDelegate {
    _delegate = newDelegate;
}

/* Sort _lastOrderedLocations by distance to a certain location.
 * @param location: Locations in the array will be sorted by distance to this parameter. (closer first)
 */
- (void) orderListForLocation: (HekaergeLocation*) location{
    if (location == nil) {
        _lastOrderedLocations = [_defaultLocations copy];
    }else
    {
        _lastOrderedLocations = [[NSMutableArray alloc] initWithArray:[_lastOrderedLocations sortedArrayUsingComparator:^(HekaergeLocation* loc1, HekaergeLocation* loc2) {
            
            //Use CLLocation built in distance calculator
            CLLocation * currLoc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
            CLLocation * location1 = [[CLLocation alloc] initWithLatitude:loc1.latitude longitude:loc1.longitude];
            CLLocation * location2 = [[CLLocation alloc] initWithLatitude:loc2.latitude longitude:loc2.longitude];
            
            CLLocationDistance dist_a = [location1 distanceFromLocation:currLoc] - loc1.radius;
            CLLocationDistance dist_b = [location2 distanceFromLocation:currLoc] - loc2.radius;
            
            //Inside both geofences
            if(dist_a < 0 && dist_b < 0){
                //Policy: if same floor, smaller geofence location first
                if(loc1.floor == loc2.floor){
                    if(loc1.radius < loc2.radius){
                        return NSOrderedAscending; //a is closer
                    }
                    else if(loc1.radius > loc2.radius){
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
            if (location.floor == loc1.floor){
                return NSOrderedAscending; //a is closer
            }
            else if(location.floor == loc2.floor){
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
 *
 */
- (HekaergeLocation*) getLastKnownLocationByBeacons {

    NSArray* beacons = [[NSArray alloc] initWithArray:[[MOCA proximityService] beacons]];
    if(beacons == nil) return nil;
    
    for (MOCABeacon *b in beacons){
        if ([b proximity] != CLProximityUnknown && [b location] != nil) {
            if([self addBeacon:b]){
                int radius = 0; //immediate
                if ([b proximity] == CLProximityFar) {
                    radius = 20;
                }
                else if([b proximity] == CLProximityNear){
                    radius = 5;
                }
                
                return [[HekaergeLocation alloc]    initWithId:b.identifier
                                                  withLocation:b.location.coordinate
                                                         floor:[b.floor doubleValue]
                                                        radius:radius];
            }
        }
    }
    
    return nil;
}


#pragma mark - API

//API

/*
 * If bluetooth is on, and a beacon (with Location) is in range, the location list 
 * will be sorted by beacon distance
 *
 */

- (NSArray * ) getOrderedLocations {
    if(_bleStatus == CBCentralManagerStatePoweredOn){
        return _lastOrderedLocations;
    }
    return _defaultLocations;
}

/*
 * Returns location with the default order.
 */

- (NSArray *) getDefaultLocations {
    return _defaultLocations;
}

//--------------------------

#pragma mark - MOCA Proximity Delegate

//We do not track proximity changes for performance reasons.
//To be discussed.

-(void)proximityService:(MOCAProximityService*)service
          didEnterRange:(MOCABeacon *)beacon
          withProximity:(CLProximity)proximity{
    
    if([self addBeacon:beacon]){
        _beaconsInRange = [[NSMutableArray alloc]initWithArray:[_beaconsInRange sortedArrayUsingComparator:^(MOCABeacon* beacon1, MOCABeacon* beacon2){
            if(beacon1.proximity == 0 ^ beacon2.proximity == 0){
                if(beacon1.proximity != 0){
                    return NSOrderedAscending;
                }
                return NSOrderedDescending;
            }
            if(beacon1.proximity < beacon2.proximity){
                return NSOrderedAscending; //1 is closer
            }
            if(beacon2.proximity < beacon1.proximity){
                return NSOrderedDescending; //2 is closer
            }
            return NSOrderedSame;
        }]];
        
        [self orderListForLocation: [self hekaergeLocationForBeacon:[_beaconsInRange objectAtIndex:0]]];
    }
}


-(void)proximityService:(MOCAProximityService*)service
           didExitRange:(MOCABeacon *)beacon
{
    for(MOCABeacon* b in _beaconsInRange){
        if(beacon.identifier == b.identifier){
            [_beaconsInRange removeObjectIdenticalTo:beacon];
            if([_beaconsInRange count] == 0){
                [self orderListForLocation: nil];
            }
            else{
                [self orderListForLocation: [self hekaergeLocationForBeacon:[_beaconsInRange objectAtIndex:0]]];
            }
            return;
        }
    }
}

#pragma mark - Utils

-(HekaergeLocation*) hekaergeLocationForBeacon: (MOCABeacon*) beacon{
    CLLocationCoordinate2D beaconCoord = beacon.location.coordinate;
    return [[HekaergeLocation alloc] initWithId:beacon.identifier
                                   withLocation:beaconCoord
                                          floor:[beacon.floor doubleValue]
                                         radius:0];
}

-(void) callDelegate
{
    if([self delegate] != nil){
        if([[self delegate] respondsToSelector:@selector(didChangeLocation:)]){
            [_delegate didChangeLocation:_lastOrderedLocations];
        }
    }
}

-(BOOL) addBeacon: (MOCABeacon*) beacon
{
    if(beacon.location != nil){
        CLLocationCoordinate2D bLoc = beacon.location.coordinate;
        double lat = bLoc.latitude;
        double lon = bLoc.longitude;
        if(lon != 0 && lat != 0){
            [_beaconsInRange addObject:beacon];
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
    
    _bleStatus = _bluetoothManager.state;

}

@end

