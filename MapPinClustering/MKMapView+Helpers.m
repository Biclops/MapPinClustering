//
//  MKMapView+Helpers.m
//  Realist
//
//  Created by David Tan on 7/13/11.
//

#import "MKMapView+Helpers.h"
#import "Macros.h"
#import <CoreLocation/CoreLocation.h>

#define SPAN_ANNOTATION_DEBUG 0

void printMapRegion(MKCoordinateRegion region)
{
    NSLog(@"mapRegion: \tlatitudeDelta:%f \tlongitudeDelta:%f \tlatitude:%f \tlongitude:%f", region.span.latitudeDelta, region.span.longitudeDelta, region.center.latitude, region.center.longitude);
}

// =============================================================================
// MKMapView (Annotations)
// =============================================================================
@implementation MKMapView(Annotations)
- (NSArray*)annotationsExceptClass:(Class)class
{
    // remove all except for the user location
    NSMutableArray* annotations = [NSMutableArray arrayWithArray:self.annotations];
    for(id obj in annotations)
    {
        if([obj isMemberOfClass:class])
            [annotations removeObject:obj];
    }

    return annotations;
}

- (MKCoordinateRegion)calculateRegionToFitAllAnnotations:(NSArray *)annotations
{
    static double BufferFactor = 1.15f;
    
    if (annotations.count == 0) {
        return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0f, 0.0f), MKCoordinateSpanMake(0.0, 0.0)); 
    }
    
    CLLocationCoordinate2D topLeftCoord; 
    topLeftCoord.latitude = -90; 
    topLeftCoord.longitude = 180; 
    
    CLLocationCoordinate2D bottomRightCoord; 
    bottomRightCoord.latitude = 90; 
    bottomRightCoord.longitude = -180; 
    
    for(id<MKAnnotation> annotation in annotations) 
    { 
        // spans to fit all with the exception to the user location
        if([annotation conformsToProtocol:@protocol(MKAnnotation)] && 
           [annotation isKindOfClass:[MKUserLocation class]] == NO)
        {
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude); 
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude); 
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude); 
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude); 
        }
    } 
    
    CONDITIONLOG(SPAN_ANNOTATION_DEBUG ,@"topLeftCoord.longitude %f", topLeftCoord.longitude);
    CONDITIONLOG(SPAN_ANNOTATION_DEBUG ,@"topLeftCoord.latitude %f", topLeftCoord.latitude);
    CONDITIONLOG(SPAN_ANNOTATION_DEBUG ,@"bottomRightCoord.longitude %f", bottomRightCoord.longitude);
    CONDITIONLOG(SPAN_ANNOTATION_DEBUG ,@"bottomRightCoord.latitude %f", bottomRightCoord.latitude);
    
    MKCoordinateRegion region; 
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5; 
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5; 
    
    // calculate the delta
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * BufferFactor;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * BufferFactor;
    
    // Add a little extra space on the sides 
    region.span.latitudeDelta *= BufferFactor; 
    region.span.longitudeDelta *= BufferFactor; 
    
    region = [self regionThatFits:region]; 
    
#if SPAN_ANNOTATION_DEBUG
    printMapRegion(region); 
#endif
    
    return region;
}

- (void)spanToFitAnnotations:(NSArray *)annotations animate:(BOOL)animate
{
    MKCoordinateRegion region = [self calculateRegionToFitAllAnnotations:annotations];
    [self setRegion:region animated:animate];
}

@end

// =============================================================================
// MKMapView (ZoomLevel)
// =============================================================================
#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
@implementation MKMapView (ZoomLevel)

#pragma mark - Map conversion methods
- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark - Helper methods
- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}


#pragma mark - Public methods
- (float)zoomLevel
{
    float zoom1 = 0.0f;
    float zoom2 = 0.0f;
    
    struct MapRegion
    {
        CLLocationDegrees left;
        CLLocationDegrees right;
        CLLocationDegrees top;
        CLLocationDegrees bottom;
    };
    
    // DVT DEBUG TODO BUG: moving around the map without zooming can change the zoom +-0.05
    // but pinch zooming in or out can be done to precision of +-0.4
    // use visibleMapRect instead
    struct MapRegion mapRegion;
    
    // numbers decrease as you move to the east(right) towards the prime meridian over Greenwich
    mapRegion.left = self.region.center.longitude - self.region.span.longitudeDelta * 0.5f;
    mapRegion.right = self.region.center.longitude + self.region.span.longitudeDelta * 0.5f;
    
    // numbers decrease as you move south(down) towards the equator
    mapRegion.top = self.region.center.latitude + self.region.span.latitudeDelta * 0.5f;    
    mapRegion.bottom = self.region.center.latitude - self.region.span.latitudeDelta * 0.5f;    
    
    if ((mapRegion.top != mapRegion.bottom) && (mapRegion.left != mapRegion.right)) 
    {
        static float const TOTAL_DEGREES_LONG = 360.0f;        // 180 degrees left and right of the prime meridian
        static float const TOTAL_DEGREES_LAT = 180.0f;         // 90 degrees above and below the equator
        static float const SIZE_OF_TILE = 256.0f;
        
        // map is still 0,0 so using window size instead
        zoom1 = logf(TOTAL_DEGREES_LONG / SIZE_OF_TILE * self.bounds.size.width / (float)(mapRegion.right - mapRegion.left)) / logf(2);
        zoom2 = logf(TOTAL_DEGREES_LAT / SIZE_OF_TILE * self.bounds.size.height / (float)(mapRegion.top - mapRegion.bottom)) / logf(2);
    }
    
    float zoomLevel = MIN(zoom1, zoom2);
    
    return zoomLevel;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self setRegion:region animated:animated];
}

@end 

@implementation MKMapView (MapPoints)
- (BOOL)isCoordinateVisible:(CLLocationCoordinate2D)coordinate
{
    CGPoint point = [self convertCoordinate:coordinate 
                              toPointToView:self];
    BOOL isVisible = NO;
    if (point.x > 0.0 && point.y > 0.0 && 
        point.x < self.frame.size.width && 
        point.y < self.frame.size.height) 
    {
        NSLog(@"Coordinate: %f %f", point.x, point.y);
        isVisible = YES;
    }
    
    return isVisible;
}

- (float)distanceFromCenter:(CLLocationCoordinate2D)coordinate
{
    CGFloat xDist = (coordinate.latitude - self.region.center.latitude);
    CGFloat yDist = (coordinate.longitude - self.region.center.longitude);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    
    return distance;
}
@end


@implementation MKMapView (Debug)
- (void)printRegion
{
    [MKMapView printRegion:self.region];
}

+ (void)printRegion:(MKCoordinateRegion)region
{
    NSLog(@"MapRegion");
    NSLog(@"center latitude %f", region.center.latitude);
    NSLog(@"center longitude %f", region.center.longitude);
    NSLog(@"span delta latitude %f", region.span.latitudeDelta);
    NSLog(@"span delta longitude %f", region.span.longitudeDelta);    
}

- (NSString*)regionDescription
{
    return [MKMapView regionDescription:self.region];
}

+ (NSString*)regionDescription:(MKCoordinateRegion)region
{
    return [NSString stringWithFormat:@"MapRegion \ncenter latitude %f \ncenter longitude %f \nspan delta latitude %f \nspan delta longitude %f", 
            region.center.latitude, 
            region.center.longitude,
            region.span.latitudeDelta,
            region.span.longitudeDelta];
}
@end