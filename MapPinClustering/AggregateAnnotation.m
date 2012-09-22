//
//  AggregateAnnotation.m
//  MapPinClustering
//
//  Created by DDT on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AggregateAnnotation.h"

@implementation AggregateAnnotation 
@synthesize coordinate = _coordinate;
@synthesize childAnnotations = _childAnnotations;

- (id)init {
    self = [super init];
    if(self) {
        _childAnnotations = [NSMutableArray array];
    }
    
    return self;
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%d properties", _childAnnotations.count];
}

- (void)addChild:(id<AggregatableAnnotation, MKAnnotation>)childAnnotation {
    [_childAnnotations addObject:childAnnotation];
    
    _coordinate = [self calculateCoordinate];    
}

- (void)removeAllChildren {
    [_childAnnotations removeAllObjects];
}

- (CLLocationCoordinate2D) calculateCoordinate {
    // calculate the average value
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(0.0, 0.0);
    
    for (id<AggregatableAnnotation, MKAnnotation> annotation in _childAnnotations) {
        coordinate.latitude += annotation.actualCoordinate.latitude;
        coordinate.longitude += annotation.actualCoordinate.longitude;
    }
    
    coordinate.latitude /= _childAnnotations.count;
    coordinate.longitude /= _childAnnotations.count;    
    
    return coordinate;
}

- (NSString *)description {
    return [NSString stringWithFormat:@" AggregateAnnotation : coordinate %f, %f", _coordinate.latitude, _coordinate.longitude]; 
}

@end
