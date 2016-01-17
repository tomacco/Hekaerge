#Hekaerge
A module to sort locations by *tomacco*

- the `Hekaerge` Class allows you to mantain a list of geo locations (`HekaergeLocation`) objects sorted by distance to your current location. 
Current location is fetched **only** via bluetooth beacons, specifically, by the beacons supported by [MOCA Platform](http://mocaplatform.com) Mobile SDKs

###Initializing a Hekaerge object

`- (instancetype)initWithLocations: (NSArray<HekaergeLocation *> *) locations`

####Parameters

- ***locations***: An array of `HekaergeLocation` that will be tracked as users moves around.
 
###Getting the sorted array

- There are two methods to get a sorted array of locations:
	-  One is **synchronous** method. The first time you instantiate `Hekaerge`, you can try to get a sorted array by calling `getOrderedLocations` just after `Hekaerge` is instantiated for the first time. It will check if there are beacons in range, if there are it will return a sorted array based on the current position. If bluetooth is off, or no beacons are in range, the locations will be get in the same order you provided them to `Hekaerge`
	- Async method; callback via delegation. When the device enters in range of a beacon, MOCA SDK reports it to `Hekaerge` and it, in turn, will return the sorted array to your delegate. Just remember to have a strong reference to your `Hekaerge` instance.

- `Hekaerge` takes account of the radius of the location to measure the distance. As buildings are not circles, you can increase the confidence by creating multiple `HekaergeLocation`s for a building.

- Example:

	- <img src="buildings.png" width=600/>

####Sorting policies

(relevant for buildings with multiple floors)  
- If two Geofences overlap, and you are inside of both, the **floor** will be used to select the right one.  
- If two Geofences overlap, **with the same floor**, and you are inside both, the smaller one will be sorted first.


####Current limitations
- Alttitude is not used to calculate distance (only a 2D plane).
- Proximity changes in the beacons in range are not used to recalculate distances. (Better performance).

###HekaergeLocation

A `HekaergeLocation` object represents a location. This object incorporates:  
- Identifier: String with name of location
- 2D Coordinate (latitude, longitude)  
- Radius: similar to a GeoFence.  
- Floor: floor level for overlapping geofences.  


###Other

Any improvement you want to make in this module is more than welcome! 😄

Sample Code:

```
@interface MyClass()
{
    Hekaerge  * _go;
}
@end
...
- (void) startHekaerge
{
    HekaergeLocation * hall1 = [[HekaergeLocation alloc] initWithId:@"hall1" latitude:41.353485 longitide:2.129052 floor:0 radius:64];
    HekaergeLocation * hall2 = [[HekaergeLocation alloc] initWithId:@"hall2" latitude:41.354400 longitide:2.129854 floor:0 radius:55];
    HekaergeLocation * hall3 = [[HekaergeLocation alloc] initWithId:@"hall3" latitude:41.355028 longitide:2.131205 floor:0 radius:49];
    HekaergeLocation * hall4 = [[HekaergeLocation alloc] initWithId:@"hall4" latitude:41.354753 longitide:2.13336 floor:0 radius:50];
    HekaergeLocation * hall5 = [[HekaergeLocation alloc] initWithId:@"hall5" latitude:41.356697 longitide:2.132073 floor:0 radius:50];
    HekaergeLocation * hall6 = [[HekaergeLocation alloc] initWithId:@"hall6" latitude:41.355234 longitide:2.134667 floor:0 radius:50];
    HekaergeLocation * hall7 = [[HekaergeLocation alloc] initWithId:@"hall7" latitude:41.357155 longitide:2.133298 floor:0 radius:50];
    HekaergeLocation * hall7Smaller = [[HekaergeLocation alloc] initWithId:@"hall7smaller" latitude:41.357155 longitide:2.133298 floor:0 radius:40];
    HekaergeLocation * hall8 = [[HekaergeLocation alloc] initWithId:@"hall8" latitude:41.3559 longitide:2.136817 floor:0 radius:105];
    HekaergeLocation * hall81 = [[HekaergeLocation alloc] initWithId:@"hall81" latitude:41.3559 longitide:2.136817 floor:1 radius:105];
    NSMutableArray *locs = [[NSMutableArray alloc] init];
    [locs addObject:hall1];
    [locs addObject:hall2];
    [locs addObject:hall3];
    [locs addObject:hall4];
    [locs addObject:hall5];
    [locs addObject:hall6];
    [locs addObject:hall7];
    [locs addObject:hall7Smaller];
    [locs addObject:hall8];
    [locs addObject:hall81];
    
    _go = [[Hekaerge alloc] initWithLocations:locs];
    _go.delegate = self;
    
    NSLog(@"🔴forcing sync...");
    //Forcing first sync with existing data
    [self didChangeLocation:[_go getDefaultLocations]];

}

-(void) didChangeLocation:(NSArray *)locations
{
    int i = 0;
    for(HekaergeLocation* loc in locations){
        NSLog(@"[%i]🔵 %@", ++i, loc.identifier);
    }
}

```