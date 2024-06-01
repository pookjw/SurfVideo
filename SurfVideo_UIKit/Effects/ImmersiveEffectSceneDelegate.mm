//
//  ImmersiveEffectSceneDelegate.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffectSceneDelegate.hpp"
#import "UIWindow+Private.h"

#if TARGET_OS_VISION
#import "SurfVideo_UIKit-Swift.h"

@implementation ImmersiveEffectSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    [window setMrui_debugOptions:(1 << 0) ^ (1 << 1) ^ (1 << 2) ^ (1 << 3) ^ (1 << 4)];
    
    __kindof UIViewController *rootViewController = SurfVideo_UIKit::ImmersiveView::makeHostingController();
    window.rootViewController = rootViewController;
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

@end
#endif
