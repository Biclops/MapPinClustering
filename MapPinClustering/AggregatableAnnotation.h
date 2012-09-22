//
//  AggregatableAnnotation.h
//  MapPinClustering
//
//  Created by Kevin Kazmierczak on 4/5/12.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// Annotation Objects must implement both AggregatableAnnotation AND MKAnnotation
@protocol AggregatableAnnotation <NSObject>
@property (nonatomic, assign) CLLocationCoordinate2D clusterCoordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D actualCoordinate;
@end

@interface AggregatableAnnotation : NSObject <MKAnnotation, AggregatableAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CLLocationCoordinate2D clusterCoordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D actualCoordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D) coordinate;

@end

