//
//  EditorViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities;
@end

NS_ASSUME_NONNULL_END
