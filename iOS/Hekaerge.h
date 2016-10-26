//
//  Hekaerge.h
//  MocaApp
//
//  Created by Iván González on 8/1/16.
//  Copyright © 2016 InnoQuant. All rights reserved.
//

@import Foundation;

@class Hekaerge;
@class HekaergeLocation;


@protocol HekaergeDelegate <NSObject>

- (void)hekaerge:(Hekaerge *)hekaerge didChangeLocation:(NSArray<HekaergeLocation *> *)locations;

@end


@interface Hekaerge : NSObject

/*
 * Locations with the default order.
 */
@property (strong, nonatomic, readonly) NSArray<HekaergeLocation *> *defaultLocations;

/*
 * If bluetooth is on, and a beacon (with Location) is in range, the locations list
 * will be sorted by beacon distance
 */
@property (strong, nonatomic, readonly) NSArray<HekaergeLocation *> *orderedLocations;

@property (weak, nonatomic) id<HekaergeDelegate> delegate;

- (instancetype)initWithLocations:(NSArray<HekaergeLocation *> *)locations;

@end
