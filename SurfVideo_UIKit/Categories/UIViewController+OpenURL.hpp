//
//  UIViewController+OpenURL.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIViewController (OpenURL)
- (void)sv_openURL:(NSURL *)URL completionHandler:(void (^ _Nullable)(BOOL success))completionHandler;
@end

NS_ASSUME_NONNULL_END
