//
//  ClusteringMapView.m
//  MapPinClustering
//
//  Created by Kevin Kazmierczak on 4/5/12.
//

#import <Foundation/Foundation.h>

#import "AggregateAnnotation.h"
#import "AggregateAnnotationView.h"
#import "ClusteringMapView.h"
#import "AggregatableAnnotation.h"
#import "MKMapView+Helpers.h"

// Prototype
bool fequal(float a, float b, float precision);

bool fequal(float a, float b, float precision)
{
    if(precision < 0) {
        [NSException raise:@"Precision must be non-negative value" format:@"precision %f invalid. Precision must be non-negative value", precision];
    }
    
    return fabs(a-b) < precision;
}

@interface ClusteringMapView ()
- (BOOL)mapViewDidZoom;
- (void)updatePinClusters;
- (void)setup;
@end

@implementation ClusteringMapView
{
    // Flag to track if the annotations have initially loaded
    BOOL hasLoaded;
    
    // The current zoom level of the map
    double zoomLevel;
    
    // The previous zoom level of the map to track if we zoom in or out
    double priorZoomLevel;
    
    // A dictionary of coordinates used to assign the clustered coordinate to non-visible pins
    NSMutableDictionary *coordDict;
    
    // Animation time interval
    NSTimeInterval interval;
    
    // Pixels for block clustering
    int distance;
    
    NSMutableDictionary *aggregateAnnotationDict;    
}

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setup];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self setup];
    }

    return self;
}

- (void)setup {
    // Set itself as the delegate so we can operate on the messages
    super.delegate = self;
    
    // Init our collections
    coordDict = [[NSMutableDictionary alloc] init];
    
    // Set the animation duration
    interval = 0.5;
    
    // Set the pixel distance used for block clustering
    distance = 40;
    
    // keeps track of the aggregate annotations
    aggregateAnnotationDict = [NSMutableDictionary dictionary]; 
}

#pragma mark - MKMapViewDelegate methods

#pragma mark - Responding to Map Position Changes

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if ([delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)]) {
        [delegate mapView:mapView regionWillChangeAnimated:animated];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    // Only update the pins if the map zoomed and we've already loaded the annotations
    if ([self mapViewDidZoom] && (hasLoaded == YES)) {

        //remove all old aggregate annotations
        [self removeAnnotations:[aggregateAnnotationDict allValues]];        
        [aggregateAnnotationDict removeAllObjects];    
        
        [self addAggregateAnnotations];
        [self updatePinClusters];
    }

    if ([delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [delegate mapView:mapView regionDidChangeAnimated:animated];
    }
}

#pragma mark - Loading the Map Data

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
    if ([delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)]) {
        [delegate mapViewWillStartLoadingMap:mapView];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if ([delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)]) {
        [delegate mapViewDidFinishLoadingMap:mapView];
    }
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    if ([delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)]) {
        [delegate mapViewDidFailLoadingMap:mapView withError:error];
    }
}

#pragma mark - Tracking the User Location

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
    if ([delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)]) {
        [delegate mapViewWillStartLocatingUser:mapView];
    }
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {
    if ([delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)]) {
        [delegate mapViewDidStopLocatingUser:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if ([delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
        [delegate mapView:mapView didUpdateUserLocation:userLocation];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    if ([delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)]) {
        [delegate mapView:mapView didFailToLocateUserWithError:error];
    }
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    if ([delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)]) {
        [delegate mapView:mapView didChangeUserTrackingMode:mode animated:animated];
    }
}

#pragma mark - Managing Annotation Views
- (void)addAnnotation:(id <MKAnnotation>)annotation {
    [super addAnnotation:annotation];
    [self addAggregateAnnotations];
}

- (void)addAnnotations:(NSArray *)annotations {
    [super addAnnotations:annotations];
    [self addAggregateAnnotations];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    MKAnnotationView *annotationView = nil;
    if([annotation isKindOfClass:[AggregateAnnotation class]]) {
        static NSString *const identifier = @"aggregateAnnotation";
        
        AggregateAnnotationView *aaView = (AggregateAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        AggregateAnnotation *aAnnotation = (AggregateAnnotation *)annotation;
        
        if (aaView == nil) {
            aaView = [[AggregateAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        }
        
        aaView.label.text = [NSString stringWithFormat:@"%d", aAnnotation.childAnnotations.count];
        annotationView = aaView;        
    } 
    else if ([delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        // Get the view from the delegate
        MKAnnotationView *view = [delegate mapView:mapView viewForAnnotation:annotation];
        
        if([annotation conformsToProtocol:@protocol(AggregatableAnnotation)]) {
            // We need them to start off in the hidden position
            view.hidden = YES;
        }
        
        return view;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    
    // We only want to update the pin clusters when the annotations aren't the user's current location
    if (hasLoaded == NO) {
        hasLoaded = YES;
        // added them but don't animate them
        [self updatePinClusters];
    }
    
    if ([delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
        [delegate mapView:mapView didAddAnnotationViews:views];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]) {
        [delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
    }
}

#pragma mark - Dragging an Annotation View

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if ([delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)]) {
        [delegate mapView:mapView annotationView:view didChangeDragState:newState fromOldState:oldState];
    }
}

#pragma mark - Selecting Annotation Views

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)]) {
        [delegate mapView:mapView didDeselectAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if([view.annotation isKindOfClass:[AggregateAnnotation class]]) {
        AggregateAnnotation *aAnnotation = view.annotation;
        
        // bundle them up to span correctly
        for(id<AggregatableAnnotation, MKAnnotation> cAnnotation in aAnnotation.childAnnotations) {
            cAnnotation.coordinate = cAnnotation.actualCoordinate;
        }
        
        [mapView spanToFitAnnotations:aAnnotation.childAnnotations animate:YES];
        
        // restore them to have them animate correctly
        for(id<AggregatableAnnotation, MKAnnotation> cAnnotation in aAnnotation.childAnnotations) {
            cAnnotation.coordinate = cAnnotation.clusterCoordinate;
        }        
    }
    
    if ([delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [delegate mapView:mapView didSelectAnnotationView:view];
    }
}

#pragma mark - Selecting Annotation Views

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    if ([delegate respondsToSelector:@selector(mapView:viewForOverlay:)]) {
        return [delegate mapView:mapView viewForOverlay:overlay];
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {
    if ([delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)]) {
        [delegate mapView:mapView didAddOverlayViews:overlayViews];
    }
}

#pragma mark - Utility methods

- (void)addAggregateAnnotations {
    // =========================
    // Add AggregateAnnotations
    // =========================
    
    // Create a dictionary of aggregatableAnnotations indexed on the block value
    NSMutableDictionary *aggregatableAnnotationsDict = [NSMutableDictionary dictionary];
    NSMutableArray *oldAggregateAnnotations = [NSMutableArray array];
    for (id<AggregatableAnnotation, MKAnnotation> annotation in [self annotations]) {
        if([annotation conformsToProtocol:@protocol(AggregatableAnnotation)]) {
            [oldAggregateAnnotations addObject:annotation];
        }
        
        // only AggregatableAnnotations allowed
        if ([annotation conformsToProtocol:@protocol(AggregatableAnnotation)] == NO) {
            continue;
        }
        
        // Get the x/y point of the annotation
        CGPoint point = [self convertCoordinate:annotation.actualCoordinate toPointToView:nil];
        CGPoint roundedPoint;
        
        // Calculate the block this point belongs to
        roundedPoint.x = roundf(point.x / distance) * distance;
        roundedPoint.y = roundf(point.y / distance) * distance;
        
        // Convert the point to a value so we can stick it in the array
        NSValue *value = [NSValue valueWithCGPoint:roundedPoint];  
        
        // check if there's a bucket for this value
        NSMutableArray *bucket = [aggregatableAnnotationsDict objectForKey:value];
        if(bucket == nil) {
            // add one if there is none
            bucket = [NSMutableArray array];
            [aggregatableAnnotationsDict setObject:bucket forKey:value];
        }
        
        [bucket addObject:annotation];
    }

    for(NSValue *value in [aggregatableAnnotationsDict allKeys]) {
        NSArray *bucket = [aggregatableAnnotationsDict objectForKey:value];
        
        // not enough annotations to get an aggregateAnnotation
        if(bucket.count > 1) {
            // create the aggregateAnnotation
            AggregateAnnotation *aAnnotation = [[AggregateAnnotation alloc] init];
            
            // add children
            for(id<AggregatableAnnotation, MKAnnotation>cAnnotation in bucket) {
                [aAnnotation addChild:cAnnotation];
            }
            
            // add annotations to map
            [super addAnnotation:aAnnotation];
            
            [aggregateAnnotationDict setObject:aAnnotation forKey:value];
        }
    }
}

/*
 *   Utility method to handle the clustering of the pins
 */
- (void)updatePinClusters {
    // Clear our collections as we'll reprocess them
    [coordDict removeAllObjects];
    
    // Loop over location and upate visibility
    for (id<AggregatableAnnotation, MKAnnotation>annotation in [self annotations]) {
        // only AggregatableAnnotations allowed
        if ([annotation conformsToProtocol:@protocol(AggregatableAnnotation)] == NO) {
            continue;
        }

        // Get the annotation view for the annotaiton
        MKPinAnnotationView *av = (MKPinAnnotationView *)[self viewForAnnotation:annotation];
        
        // Get the x/y point of the annotation
        CGPoint point = [self convertCoordinate:annotation.actualCoordinate toPointToView:nil];
        CGPoint roundedPoint;
        
        // Calculate the block this point belongs to
        roundedPoint.x = roundf(point.x / distance) * distance;
        roundedPoint.y = roundf(point.y / distance) * distance;
        
        // Convert the point to a value so we can stick it in the array
        NSValue *value = [NSValue valueWithCGPoint:roundedPoint];
        
        // move towards aggregate annotations
        if([[aggregateAnnotationDict allKeys] containsObject:value]) {
            AggregateAnnotation *aAnnotation = [aggregateAnnotationDict objectForKey:value];
            
            // don't move it if you're already at the aggregateAnnotation coordinate
            if (annotation.coordinate.latitude != aAnnotation.coordinate.latitude &&
                annotation.coordinate.longitude != aAnnotation.coordinate.latitude) {
                // have it fade away as well
                av.hidden = NO;
                av.alpha = 1.0f;
                [UIView animateWithDuration:interval 
                                 animations:^{
                                     annotation.coordinate = aAnnotation.coordinate;
                                     annotation.clusterCoordinate = aAnnotation.coordinate;
                                     av.alpha = 0.0f;
                                 }
                                 completion:^(BOOL finished) {
                                     av.hidden = YES;
                                     
                                     // reset the alpha as well
                                     av.alpha = 1.0f;
                                 }
                ];
            }
        }
        else {
            // move towards the real location
            av.hidden = NO;
            
            [UIView animateWithDuration:interval
                             animations:^{
                                 annotation.coordinate = annotation.actualCoordinate;
                             } 
                             completion:^(BOOL finished) {
                             }
            ];
        }
    }
    
    priorZoomLevel = zoomLevel;
}

/*
 *   Clever way to determine map zooms as it's a bit tricky if you try to watch the current lat/lon
 *   deltas.
 *
 *   This was taken from the revolver.be example for his REVClusterMapView
 */
- (BOOL)mapViewDidZoom {
    if (fequal(zoomLevel, self.visibleMapRect.size.width * self.visibleMapRect.size.height, 0.1f)) {
        zoomLevel = self.visibleMapRect.size.width * self.visibleMapRect.size.height;
        return NO;
    }

    zoomLevel = self.visibleMapRect.size.width * self.visibleMapRect.size.height;
    return YES;
}

/*
 *   Utility method to center the map based on an array of annotations.
 */
- (void)centerMapOnAnnotationSet:(NSArray *)annotations {
    float minLng = 0;
    float maxLng = 0;
    float minLat = 0;
    float maxLat = 0;

    // Collect the min/max lat/longs
    for (id<AggregatableAnnotation, MKAnnotation> annotation in annotations) {
        if ((minLat == 0) || (annotation.coordinate.latitude < minLat)) {
            minLat = annotation.coordinate.latitude;
        }

        if ((maxLat == 0) || (annotation.coordinate.latitude > maxLat)) {
            maxLat = annotation.coordinate.latitude;
        }

        if ((minLng == 0) || (annotation.coordinate.longitude < minLng)) {
            minLng = annotation.coordinate.longitude;
        }

        if ((maxLng == 0) || (annotation.coordinate.longitude > maxLng)) {
            maxLng = annotation.coordinate.longitude;
        }
    }

    float mapPadding = 1.1;
    float minVisLat = 0.01;

    // Create a span based on those lat/longs and apply a bit of padding
    MKCoordinateRegion region;
    region.center.latitude = (minLat + maxLat) / 2;
    region.center.longitude = (minLng + maxLng) / 2;

    region.span.latitudeDelta = (maxLat - minLat) * mapPadding;

    region.span.latitudeDelta = (region.span.latitudeDelta < minVisLat) ? minVisLat : region.span.latitudeDelta;

    region.span.longitudeDelta = (maxLng - minLng) * mapPadding;

    MKCoordinateRegion scaledRegion = [self regionThatFits:region];
    [self setRegion:scaledRegion animated:YES];
}

@end