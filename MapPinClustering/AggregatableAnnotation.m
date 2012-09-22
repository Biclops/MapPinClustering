//
//  AggregatableAnnotation.m
//  MapPinClustering
//
//  Created by Kevin Kazmierczak on 4/5/12.
//

#import "AggregatableAnnotation.h"

@implementation AggregatableAnnotation

@synthesize title, subtitle, coordinate, clusterCoordinate, actualCoordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D) aCoordinate {
    self = [super init];
    if (self) {
        // The coordinate property is really just it's current location, which is set to
        // either the clusterCoordinate or the actualCoordinate from the ClusteredMapView
        coordinate = aCoordinate;
        
        // Set the current cluster coordinate to the original coordinate by default
        clusterCoordinate = aCoordinate;
        
        // Set the actual coordinate
        actualCoordinate = aCoordinate;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"coordinate %f, %f", coordinate.latitude, coordinate.longitude]; 
}

@end