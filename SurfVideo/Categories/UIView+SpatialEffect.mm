//
//  UIView+SpatialEffect.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/4/24.
//

#import "UIView+SpatialEffect.hpp"
#import <objc/message.h>
#import <objc/runtime.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

namespace ns_SpatialEffect {
    void *blueFilterKey = &blueFilterKey;
    void *topGradientLayerKey = &topGradientLayerKey;
    void *leftGradientLayerKey = &leftGradientLayerKey;
    void *rightGradientLayerKey = &rightGradientLayerKey;
    void *bottomGradientLayerKey = &bottomGradientLayerKey;
    void *topLeftGradientLayerKey = &topLeftGradientLayerKey;
    void *topRightGradientLayerKey = &topRightGradientLayerKey;
    void *bottomRightGradientLayerKey = &bottomRightGradientLayerKey;
    void *bottomLeftGradientLayerKey = &bottomLeftGradientLayerKey;
    void *centerLayerKey = &centerLayerKey;
    void *gradientLayerMaskKey = &gradientLayerMaskKey;
}

__attribute__((objc_direct_members))
@interface _SVBackdropView : UIView
@end

@implementation _SVBackdropView

+ (Class)layerClass {
    return objc_lookUpClass("CABackdropLayer");
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    __kindof CALayer *backdropLayer = self.layer;
    CGRect bounds = backdropLayer.bounds;
    
    auto topGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::topGradientLayerKey));
    topGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * 0.05f,
                                        CGRectGetMinY(bounds),
                                        CGRectGetWidth(bounds) * 0.9f,
                                        CGRectGetHeight(bounds) * 0.05f);
    
    auto leftGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::leftGradientLayerKey));
    leftGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds),
                                         CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.05f,
                                         CGRectGetWidth(bounds) * 0.05f,
                                         CGRectGetHeight(bounds) * 0.9f);
    
    auto rightGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::rightGradientLayerKey));
    rightGradientLayer.frame = CGRectMake(CGRectGetMaxX(bounds) * 0.95f,
                                          CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.05f,
                                          CGRectGetWidth(bounds) * 0.05f,
                                          CGRectGetHeight(bounds) * 0.9f);
    
    auto bottomGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::bottomGradientLayerKey));
    bottomGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * 0.05f,
                                           CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.95f,
                                           CGRectGetWidth(bounds) * 0.9f,
                                           CGRectGetHeight(bounds) * 0.05f);
    
    auto topLeftGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::topLeftGradientLayerKey));
    topLeftGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds),
                                            CGRectGetMinY(bounds),
                                            CGRectGetWidth(bounds) * 0.05f,
                                            CGRectGetHeight(bounds) * 0.05f);
    
    auto topRightGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::topRightGradientLayerKey));
    topRightGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * 0.95f,
                                             CGRectGetMinY(bounds),
                                             CGRectGetWidth(bounds) * 0.05f,
                                             CGRectGetHeight(bounds) * 0.05f);
    
    auto bottomRightGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::bottomRightGradientLayerKey));
    bottomRightGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * 0.95f,
                                                CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.95f,
                                                CGRectGetWidth(bounds) * 0.05f,
                                                CGRectGetHeight(bounds) * 0.05f);
    
    auto bottomLeftGradientLayer = static_cast<CAGradientLayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::bottomLeftGradientLayerKey));
    bottomLeftGradientLayer.frame = CGRectMake(CGRectGetMinX(bounds),
                                               CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.95f,
                                               CGRectGetWidth(bounds) * 0.05f,
                                               CGRectGetHeight(bounds) * 0.05f);
    
    auto centerLayer = static_cast<CALayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::centerLayerKey));
    centerLayer.frame = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * 0.05f,
                                   CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 0.05f,
                                   CGRectGetWidth(bounds) * 0.9f,
                                   CGRectGetHeight(bounds) * 0.9f);
    
    auto gradientLayerMask = static_cast<CALayer *>(objc_getAssociatedObject(self, ns_SpatialEffect::gradientLayerMaskKey));
    gradientLayerMask.frame = bounds;
}

@end

@implementation UIView (SpatialEffect)

- (BOOL)sv_spatialEffect {
    return [self _sv_backdropView] != nil;
}

- (void)sv_setSpatialEffect:(BOOL)sv_spatialEffect {
    _SVBackdropView * _Nullable backdropView = [self _sv_backdropView];
    
    if (sv_spatialEffect) {
        if (backdropView) {
            [backdropView bringSubviewToFront:self.subviews.lastObject];
            return;
        }
        
        _SVBackdropView *backdropView = [[_SVBackdropView alloc] initWithFrame:self.bounds];
        __kindof CALayer *backdropLayer = backdropView.layer;
        reinterpret_cast<void (*)(id, SEL, CGFloat)>(objc_msgSend)(backdropLayer, sel_registerName("setZoom:"), 0.05f);
        
        backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:backdropView];
        
        //
        
        NSURL *url = [NSBundle.mainBundle URLForResource:@"spatial_blur_overlay" withExtension:UTTypePNG.preferredFilenameExtension];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        CGImageRef grdImageRef = image.CGImage;
        
        id blurFilter = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("CAFilter"), sel_registerName("filterWithName:"), @"variableBlur");
        [blurFilter setValue:(__bridge id)grdImageRef forKey:@"inputMaskImage"];
        [blurFilter setValue:@5.f forKey:@"inputRadius"];
        [blurFilter setValue:@NO forKey:@"inputNormalizeEdges"];
        [blurFilter setValue:@"low" forKey:@"inputQuality"];
        
        self.layer.filters = @[
            blurFilter
        ];
        
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::blueFilterKey, blurFilter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        //
        
        CAGradientLayer *topGradientLayer = [CAGradientLayer new];
        topGradientLayer.startPoint = CGPointMake(0.f, 1.f);
        topGradientLayer.endPoint = CGPointMake(0.f, 0.f);
        topGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::topGradientLayerKey, topGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *leftGradientLayer = [CAGradientLayer new];
        leftGradientLayer.startPoint = CGPointMake(1.f, 0.f);
        leftGradientLayer.endPoint = CGPointMake(0.f, 0.f);
        leftGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::leftGradientLayerKey, leftGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *rightGradientLayer = [CAGradientLayer new];
        rightGradientLayer.startPoint = CGPointMake(0.f, 0.f);
        rightGradientLayer.endPoint = CGPointMake(1.f, 0.f);
        rightGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::rightGradientLayerKey, rightGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *bottomGradientLayer = [CAGradientLayer new];
        bottomGradientLayer.startPoint = CGPointMake(0.f, 0.f);
        bottomGradientLayer.endPoint = CGPointMake(0.f, 1.f);
        bottomGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::bottomGradientLayerKey, bottomGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *topLeftGradientLayer = [CAGradientLayer new];
        topLeftGradientLayer.type = kCAGradientLayerRadial;
        topLeftGradientLayer.startPoint = CGPointMake(1.f, 1.f);
        topLeftGradientLayer.endPoint = CGPointMake(0.f, 0.f);
        topLeftGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::topLeftGradientLayerKey, topLeftGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *topRightGradientLayer = [CAGradientLayer new];
        topRightGradientLayer.type = kCAGradientLayerRadial;
        topRightGradientLayer.startPoint = CGPointMake(0.f, 1.f);
        topRightGradientLayer.endPoint = CGPointMake(1.f, 0.f);
        topRightGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::topRightGradientLayerKey, topRightGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *bottomRightGradientLayer = [CAGradientLayer new];
        bottomRightGradientLayer.type = kCAGradientLayerRadial;
        bottomRightGradientLayer.startPoint = CGPointMake(0.f, 0.f);
        bottomRightGradientLayer.endPoint = CGPointMake(1.f, 1.f);
        bottomRightGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::bottomRightGradientLayerKey, bottomRightGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CAGradientLayer *bottomLeftGradientLayer = [CAGradientLayer new];
        bottomLeftGradientLayer.type = kCAGradientLayerRadial;
        bottomLeftGradientLayer.startPoint = CGPointMake(1.f, 0.f);
        bottomLeftGradientLayer.endPoint = CGPointMake(0.f, 1.f);
        bottomLeftGradientLayer.colors = @[
            (id)UIColor.whiteColor.CGColor,
            (id)[UIColor.whiteColor colorWithAlphaComponent:0.f].CGColor
        ];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::bottomLeftGradientLayerKey, bottomLeftGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CALayer *centerLayer = [CALayer new];
        centerLayer.backgroundColor = UIColor.blackColor.CGColor;
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::centerLayerKey, centerLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        CALayer *gradintLayerMask = [CALayer new];
        [gradintLayerMask addSublayer:topGradientLayer];
        [gradintLayerMask addSublayer:leftGradientLayer];
        [gradintLayerMask addSublayer:rightGradientLayer];
        [gradintLayerMask addSublayer:bottomGradientLayer];
        [gradintLayerMask addSublayer:topLeftGradientLayer];
        [gradintLayerMask addSublayer:topRightGradientLayer];
        [gradintLayerMask addSublayer:bottomRightGradientLayer];
        [gradintLayerMask addSublayer:bottomLeftGradientLayer];
        [gradintLayerMask addSublayer:centerLayer];
        objc_setAssociatedObject(backdropView, ns_SpatialEffect::gradientLayerMaskKey, gradintLayerMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [topGradientLayer release];
        [leftGradientLayer release];
        [rightGradientLayer release];
        [bottomGradientLayer release];
        [topLeftGradientLayer release];
        [topRightGradientLayer release];
        [bottomRightGradientLayer release];
        [bottomLeftGradientLayer release];
        [centerLayer release];
        
        assert(self.layer.mask == nil);
        self.layer.mask = gradintLayerMask;
        [gradintLayerMask release];
    } else {
        if (backdropView == nil) return;
        
        CALayer *gradientLayerMask = objc_getAssociatedObject(backdropView, ns_SpatialEffect::gradientLayerMaskKey);
        id blurFilter = objc_getAssociatedObject(backdropView, ns_SpatialEffect::blueFilterKey);
        
        if ([self.layer.mask isEqual:gradientLayerMask]) {
            self.layer.mask = nil;
        }
        
        NSMutableArray *mutableFilters = [self.layer.filters mutableCopy];
        [mutableFilters removeObject:blurFilter];
        self.layer.filters = mutableFilters;
        [mutableFilters release];
        
        [backdropView removeFromSuperview];
    }
}

- (_SVBackdropView * _Nullable)_sv_backdropView __attribute__((objc_direct)) {
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:_SVBackdropView.class]) {
            return static_cast<_SVBackdropView *>(subview);
        }
    }
    
    return nil;
}

@end
