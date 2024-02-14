//
//  EditorTrackViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EditorService.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewController : UIViewController
@property (assign, nonatomic) CMTime currentTime; // KVO compliant
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithEditorViewModel:(EditorService *)editorViewModel;
@end

NS_ASSUME_NONNULL_END
