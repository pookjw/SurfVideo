//
//  UIViewController+OpenURL.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import "UIViewController+OpenURL.hpp"

@implementation UIViewController (OpenURL)

- (void)sv_openURL:(NSURL *)URL completionHandler:(void (^)(BOOL))completionHandler {
    UIWindowScene * _Nullable windowScene = self.view.window.windowScene;
    
    if (windowScene == nil) {
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:completionHandler];
    } else {
        [windowScene openURL:URL options:nil completionHandler:completionHandler];
    }
}

@end
