//
//  UIScrollView+ScrollWithHandTracking.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import "UIScrollView+ScrollWithHandTracking.hpp"

#if TARGET_OS_VISION

#import <ARKit/ARKit.h>
#import <objc/runtime.h>
#import "UIScrollView+Private.h"
#include <cmath>

__attribute__((objc_direct_members))
@interface _SVHandTrackingScrollingConfiguration : NSObject
@property (class, assign, readonly, nonatomic) void *associationKey;
@property (retain, readonly, nonatomic) ar_session_t session;
@property (retain, nonatomic, nullable) ar_hand_tracking_provider_t handTrackingProvider;
@property (assign, nonatomic) double sensitivity;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSession:(ar_session_t)session sensitivity:(double)sensitivity;
@end

@implementation _SVHandTrackingScrollingConfiguration

+ (void *)associationKey {
    static void *associationKey = &associationKey;
    return associationKey;
}

- (instancetype)initWithSession:(ar_session_t)session sensitivity:(double)sensitivity {
    if (self = [super init]) {
        _session = ar_retain(session);
        _sensitivity = sensitivity;
    }
    
    return self;
}

- (void)dealloc {
    if (auto session = _session) {
        ar_session_stop(session);
        ar_release(session);
    }
    
    ar_release(_handTrackingProvider);
    [super dealloc];
}

@end


__attribute__((objc_direct_members))
@interface UIScrollView (ScrollWithHandTracking_Private)
@property (retain, nonatomic, nullable, setter=set_sv_sht_configuration:) _SVHandTrackingScrollingConfiguration *sv_sht_configuration; 
@end

@implementation UIScrollView (ScrollWithHandTracking_Private)

- (_SVHandTrackingScrollingConfiguration *)sv_sht_configuration {
    return objc_getAssociatedObject(self, _SVHandTrackingScrollingConfiguration.associationKey);
}

- (void)set_sv_sht_configuration:(_SVHandTrackingScrollingConfiguration *)sv_sht_configuration {
    objc_setAssociatedObject(self, _SVHandTrackingScrollingConfiguration.associationKey, sv_sht_configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIScrollView (ScrollWithHandTracking)

- (void)sv_enableHandTrackingHorizontalScrollingWithSensitivity:(double)sensitivity {
    if (!ar_hand_tracking_provider_is_supported()) {
        NSLog(@"Hand Tracking is not supported on this environment.");
        return;
    }
    
    if (_SVHandTrackingScrollingConfiguration *configuration = self.sv_sht_configuration) {
        configuration.sensitivity = sensitivity;
        return;
    }
    
    ar_session_t session = [self sv_sht_makeARSession];
    
    _SVHandTrackingScrollingConfiguration *configuration = [[_SVHandTrackingScrollingConfiguration alloc] initWithSession:session sensitivity:sensitivity];
    self.sv_sht_configuration = configuration;
    [configuration release];
    
    __weak auto weakSelf = self;
    
    [self sv_sht_requestAuthorizationWithSession:session completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            auto _self = weakSelf;
            if (_self == nil) return;
            
            if (!granted) {
                UIWindowScene * _Nullable windowScene = _self.window.windowScene;
                NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                
                if (windowScene) {
                    [windowScene openURL:URL options:nil completionHandler:nil];
                } else {
                    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
                }
                
                return;
            }
            
            //
            
            _SVHandTrackingScrollingConfiguration *configuration = _self.sv_sht_configuration;
            ar_hand_tracking_provider_t handTrackingProvider = [_self sv_sht_makeHandTrackingProvider];
            configuration.handTrackingProvider = handTrackingProvider;
            
            ar_data_providers_t dataProviders = ar_data_providers_create_with_data_providers(handTrackingProvider, nil);
            ar_session_run(session, dataProviders);
            ar_release(dataProviders);
        });
    }];
}

- (void)sv_disableHandTrackingHorizontalScrolling {
    _SVHandTrackingScrollingConfiguration *configuration = self.sv_sht_configuration;
    
    if (configuration == nil) return;
    
    ar_session_stop(configuration.session);
    objc_setAssociatedObject(self, _SVHandTrackingScrollingConfiguration.associationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ar_session_t)sv_sht_makeARSession __attribute__((objc_direct)) {
    ar_session_t session = ar_session_create();
    
    ar_session_set_data_provider_state_change_handler(session, NULL, ^(ar_data_providers_t  _Nonnull data_providers, ar_data_provider_state_t new_state, ar_error_t  _Nullable error, ar_data_provider_t  _Nullable failed_data_provider) {
        if (error != nil) {
            CFErrorRef cfError = ar_error_copy_cf_error(error);
            ar_release(error);
            CFShow(cfError);
            CFRelease(cfError);
            return;
        }
    });
    
    return [session autorelease];
}

- (ar_hand_tracking_provider_t)sv_sht_makeHandTrackingProvider __attribute__((objc_direct)) {
    ar_hand_tracking_configuration_t configuration = ar_hand_tracking_configuration_create();
    ar_hand_tracking_provider_t handTrackingProvider = ar_hand_tracking_provider_create(configuration);
    ar_release(configuration);
    
    __weak auto weakSelf = self;
    
    ar_hand_tracking_provider_set_update_handler(handTrackingProvider, NULL, ^(ar_hand_anchor_t  _Nonnull hand_anchor_left, ar_hand_anchor_t  _Nonnull hand_anchor_right) {
        auto _self = weakSelf;
        if (_self == nil) return;
        if (_self.isDragging || _self.isDecelerating) return;
        
        __block float meanAngle = 0.f;
        
        ar_hand_skeleton_t rightHandSkeleton = ar_hand_anchor_get_hand_skeleton(hand_anchor_right);
        
        ar_hand_skeleton_enumerate_joints(rightHandSkeleton, ^bool(ar_skeleton_joint_t  _Nonnull joint) {
            simd_float4x4 matrix = ar_skeleton_joint_get_anchor_from_joint_transform(joint);
            simd_quatf rotation = simd_quaternion(matrix);
            
            meanAngle += simd_angle(rotation);
            
            return true;
        });
        
        float countf = (float)ar_hand_skeleton_get_joint_count(rightHandSkeleton);
        meanAngle /= countf;
        
        //
        
        _SVHandTrackingScrollingConfiguration *configuration = _self.sv_sht_configuration;
        
        CGPoint contentOffset = _self.contentOffset;
        contentOffset.x += (CGFloat)((1.2f - meanAngle) * configuration.sensitivity);
        
        UIEdgeInsets _effectiveContentInset = _self._effectiveContentInset;
        contentOffset.x = std::fmax(0., std::fmin(contentOffset.x, _self.contentSize.width - _self.bounds.size.width + _effectiveContentInset.left + _effectiveContentInset.right));
        
        [_self setContentOffset:contentOffset animated:NO];
    });
    
    return [handTrackingProvider autorelease];
}

- (void)sv_sht_requestAuthorizationWithSession:(ar_session_t)session completionHandler:(void (^)(BOOL granted))completionHandler __attribute__((objc_direct)) {
    ar_authorization_type_t authorizationTypes = ar_hand_tracking_provider_get_required_authorization_type();
    
    ar_session_request_authorization(session, authorizationTypes, ^(ar_authorization_results_t  _Nonnull authorization_results, ar_error_t  _Nullable error) {
        if (error != nil) {
            CFErrorRef cfError = ar_error_copy_cf_error(error);
            ar_release(error);
            CFShow(cfError);
            CFRelease(cfError);
            return;
        }
        
        __block BOOL granted = YES;
        
        ar_authorization_results_enumerate_results(authorization_results, ^bool(ar_authorization_result_t  _Nonnull authorization_result) {
            ar_authorization_status_t status = ar_authorization_result_get_status(authorization_result);
            
            if (status == ar_authorization_status_allowed) {
                return true;
            } else {
                granted = NO;
                return false;
            }
        });
        
        completionHandler(granted);
    });
}

@end

#endif
