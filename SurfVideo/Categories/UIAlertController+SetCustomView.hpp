//
//  UIAlertController+SetCustomView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/10/23.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIAlertController (SetCustomView)
- (void)sv_setSeparatedHeaderView:(UIView *)separatedHeaderView;
- (void)sv_setHeaderView:(UIView *)headerView;
- (void)sv_setContentView:(UIView *)contentView;
@end

NS_ASSUME_NONNULL_END
