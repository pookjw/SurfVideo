//
//  EditorMenuOrnamentViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorMenuOrnamentViewController : UIViewController
@end

NS_ASSUME_NONNULL_END
#endif
