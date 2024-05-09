//
//  PLVideoView+Swizzle.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/9/24.
//

#import "PLVideoView+Swizzle.hpp"
#import "UIImagePickerController+Private.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSNotificationName const SV_PLVideoViewDidMoviePlayerReadyToPlayNotification = @"SV_PLVideoViewDidMoviePlayerReadyToPlayNotification";

namespace sv_PLVideoView {
namespace moviePlayerReadyToPlay {
void (*original)(__kindof UIView *, SEL, id);
void custom(__kindof UIView *self, SEL _cmd, id /* PLMoviePlayerController * */ moviePlayerController) {
    original(self, _cmd, moviePlayerController);
    [NSNotificationCenter.defaultCenter postNotificationName:SV_PLVideoViewDidMoviePlayerReadyToPlayNotification object:self];
}
}
}

@implementation UIResponder (PLVideoView_Swizzle)

+ (void)load {
    if (UIImagePickerLoadPhotoLibraryIfNecessary()) {
        using namespace sv_PLVideoView::moviePlayerReadyToPlay;
        
        Method method = class_getInstanceMethod(objc_lookUpClass("PLVideoView"), sel_registerName("moviePlayerReadyToPlay:"));
        original = (decltype(original))method_getImplementation(method);
        method_setImplementation(method, (IMP)custom);
    }
}

@end
