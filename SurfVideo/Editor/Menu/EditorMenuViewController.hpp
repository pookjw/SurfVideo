//
//  EditorMenuViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import <UIKit/UIKit.h>
#import "EditorService.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorMenuViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(EditorService *)editorService;
@end

NS_ASSUME_NONNULL_END
