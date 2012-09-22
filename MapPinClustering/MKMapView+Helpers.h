//
//  MKMapView+Helpers.h
//  Realist
//
//  Created by David Tan on 7/13/11.
//
#import <MapKit/MapKit.h>

void printMapRegion(MKCoordinateRegion region);

@interface MKMapView(Annotations)
- (NSArray*)annotationsExceptClass:(Class)class;
- (void)spanToFitAnnotations:(NSArray *)annotations animate:(BOOL)animate;
@end

@interface MKMapView (ZoomLevel)
- (float)zoomLevel;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;
@end 

@interface MKMapView (MapPoints)
- (BOOL)isCoordinateVisible:(CLLocationCoordinate2D)coordinate;
- (float)distanceFromCenter:(CLLocationCoordinate2D)coordinate;
@end

@interface MKMapView (Debug)
- (void)printRegion;
+ (void)printRegion:(MKCoordinateRegion)region;

- (NSString*)regionDescription;
+ (NSString*)regionDescription:(MKCoordinateRegion)region;
@end
