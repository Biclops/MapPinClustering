//
//  ViewController.m
//  MapPinClustering
//
//  Created by Kevin Kazmierczak on 4/5/12.
//

#import "ViewController.h"
#import "AggregatableAnnotation.h"
#import "ClusteringMapView.h"
#import "AggregateAnnotation.h"
#import "AggregateAnnotationView.h"
#import "MKMapView+Helpers.h"

@interface ViewController ()
- (void)loadLocations;
@end

@implementation ViewController {
    NSMutableArray *locations;
}

@synthesize mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        locations = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark - View methods

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    // Load up our locations
    [self loadLocations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation {
    // Create out mapView annotation
    MKAnnotationView *annotationView = nil;

    if([annotation conformsToProtocol:@protocol(AggregatableAnnotation)]) {
        static NSString *const identifier = @"pin";

        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[map dequeueReusableAnnotationViewWithIdentifier:identifier];

        if (pinView == nil) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        }

        pinView.pinColor = MKPinAnnotationColorRed;
        pinView.animatesDrop = NO;
        pinView.canShowCallout = YES;
        
        annotationView = pinView;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {

}

#pragma mark - Utility methods
- (void)loadLocations {
    // Load up our locations from the locations.plist file that contains a few lat/lat records
    // around the boston area.
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"locations" ofType:@"plist"];
    NSDictionary *locationList = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    // Loop over the locations and create an annotation record for them using the special
    // AggregatableAnnotation class
    for (NSDictionary *d in locationList) {
        NSDictionary *dLoc = [locationList objectForKey:d];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dLoc valueForKey:@"lat"] doubleValue], [[dLoc valueForKey:@"lon"] doubleValue]);

        // TEST isolate to points near Nantucket Island
        //if(location.latitude > 42.3){
        //    continue;
        //}
        
        AggregatableAnnotation *annotation = [[AggregatableAnnotation alloc] initWithCoordinate:location];
        // Name these to whatever you want really
        annotation.title = @"Pin";
        annotation.subtitle = @"Subtitle";

        [locations addObject:annotation];
    }

    // Center out map on our locations
    [mapView spanToFitAnnotations:locations animate:YES];
    
    // Add our annotations to the map
    [mapView addAnnotations:locations];
}

@end