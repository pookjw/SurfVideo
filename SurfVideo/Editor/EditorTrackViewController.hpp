//
//  EditorTrackViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <memory>
#import "EditorViewModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithEditorViewModel:(std::shared_ptr<EditorViewModel>)editorViewModel;
@property (copy, nonatomic) AVComposition *composition;
@end

NS_ASSUME_NONNULL_END
