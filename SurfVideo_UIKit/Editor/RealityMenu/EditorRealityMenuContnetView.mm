//
//  EditorRealityMenuContnetView.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import "EditorRealityMenuContnetView.hpp"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface EditorRealityMenuContnetView ()
@property (copy, nonatomic) EditorRealityMenuContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) UIImageView *imageView;
@end

@implementation EditorRealityMenuContnetView
@synthesize imageView = _imageView;

- (instancetype)initWithContentConfiguration:(EditorRealityMenuContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        _contentConfiguration = [contentConfiguration copy];
        
        UIImageView *imageView = self.imageView;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:imageView];
        [NSLayoutConstraint activateConstraints:@[
            [imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
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
    return [configuration isKindOfClass:EditorRealityMenuContentConfiguration.class];
}

- (void)setContentConfiguration:(EditorRealityMenuContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    //
    
    EditorRealityMenuItemModelType type = contentConfiguration.itemModel.type;
    
    switch (type) {
        case EditorRealityMenuItemModelTypeImmersiveSpace: {
            if (contentConfiguration.isSelected) {
                self.imageView.image = [UIImage systemImageNamed:@"visionpro.fill"];
            } else {
                self.imageView.image = [UIImage systemImageNamed:@"visionpro"];
            }
            break;
        }
        case EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking: {
            if (contentConfiguration.isSelected) {
                self.imageView.image = [UIImage systemImageNamed:@"hand.draw.fill"];
            } else {
                self.imageView.image = [UIImage systemImageNamed:@"hand.draw"];
            }
            break;
        }
        default:
            break;
    }
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.backgroundColor = UIColor.clearColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.tintColor = UIColor.whiteColor;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

@end

#endif
