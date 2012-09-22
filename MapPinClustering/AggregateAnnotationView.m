//
//  AggregateAnnotationView.m
//  MapPinClustering
//
//  Created by DDT on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AggregateAnnotationView.h"

@implementation AggregateAnnotationView
@synthesize label = _label;
- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self) {
        self.image = [UIImage imageNamed:@"cluster.png"];
        self.canShowCallout = NO;   
        self.calloutOffset = CGPointMake(0.0, 0.0);
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        _label.textColor = [UIColor whiteColor];
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont boldSystemFontOfSize:11]; 
        _label.textAlignment = UITextAlignmentCenter;
        _label.shadowColor = [UIColor blackColor];
        _label.shadowOffset = CGSizeMake(0,-1);
        [self addSubview:_label];
    }
    
    return self;
}

@end
