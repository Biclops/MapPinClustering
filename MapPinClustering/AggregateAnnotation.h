//
//  AggregateAnnotation.h
//  MapPinClustering
//
//  Created by DDT on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "AggregatableAnnotation.h"

@interface AggregateAnnotation : NSObject <MKAnnotation>

@property (nonatomic, retain) NSMutableArray *childAnnotations;

- (id) init;
- (void) addChild:(id<AggregatableAnnotation, MKAnnotation>) childAnnotation;
- (void) removeAllChildren;

@end
