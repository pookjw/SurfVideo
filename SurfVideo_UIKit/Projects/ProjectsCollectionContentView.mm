//
//  ProjectsCollectionContentView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "ProjectsCollectionContentView.hpp"
#import "UIView+Private.h"
#import <SurfVideoCore/SVProjectsManager.hpp>

__attribute__((objc_direct_members))
@interface ProjectsCollectionContentView ()
@property (copy, nonatomic) ProjectsCollectionContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, readonly, nonatomic) UIImageView *imageView;
@end

@implementation ProjectsCollectionContentView

@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize imageView = _imageView;

- (instancetype)initWithContentConfiguration:(ProjectsCollectionContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        self.layer.cornerRadius = 8.f;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.masksToBounds = YES;
        [self setupImageView];
        [self setupActivityIndicatorView];
        self.contentConfiguration = contentConfiguration;
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_activityIndicatorView release];
    [_imageView release];
    [super dealloc];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = configuration;
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:ProjectsCollectionContentConfiguration.class];
}

- (void)setContentConfiguration:(ProjectsCollectionContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    UIImageView *imageView = self.imageView;
    UIActivityIndicatorView *activityIndicatorView = self.activityIndicatorView;
    __weak auto weakSelf = self;
    
    imageView.hidden = YES;
    activityIndicatorView.hidden = NO;
    [activityIndicatorView startAnimating];
    
    [SVProjectsManager.sharedInstance managedObjectContextWithCompletionHandler:^(NSManagedObjectContext * _Nullable managedObjectContext) {
        [managedObjectContext performBlock:^{
            SVVideoProject *videoProject = [managedObjectContext objectWithID:contentConfiguration.videoProjectObjectID];
            NSData *thumbnailImageTIFFData = videoProject.thumbnailImageTIFFData;
            
            UIImage *image = [UIImage imageWithData:thumbnailImageTIFFData];
            
            [image prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    auto retainedSelf = weakSelf;
                    if (retainedSelf == nil) return;
                    if (![retainedSelf.contentConfiguration isEqual:contentConfiguration]) return;
                    
                    imageView.image = image;
                    imageView.hidden = NO;
                    [activityIndicatorView stopAnimating];
                    activityIndicatorView.hidden = YES;
                });
            }];
        }];
    }];
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (auto activityIndicatorView = _activityIndicatorView) return activityIndicatorView;
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    
    _activityIndicatorView = [activityIndicatorView retain];
    return [activityIndicatorView autorelease];
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

- (void)setupImageView __attribute__((objc_direct)) {
    UIImageView *imageView = self.imageView;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:imageView];
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

- (void)setupActivityIndicatorView __attribute__((objc_direct)) {
    UIActivityIndicatorView *activityIndicatorView = self.activityIndicatorView;
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:activityIndicatorView];
    [NSLayoutConstraint activateConstraints:@[
        [activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

@end
