//
//  UIView+UIViewController_PlatterOrnament.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "UIViewController+PlatterOrnament.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

@implementation UIViewController (PlatterOrnament)

- (id)sv_platterOrnament {
    __kindof UIViewController * _Nullable platterOrnamentRootViewController = self.parentViewController;
    
    if ([platterOrnamentRootViewController isKindOfClass:objc_lookUpClass("_MRUIPlatterOrnamentRootViewController")]) {
        // MRUIPlatterOrnament *
        id ornament = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(platterOrnamentRootViewController, sel_registerName("ornament"));
        
        return ornament;
    } else {
        return nil;
    }
}

@end
