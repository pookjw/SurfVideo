//
//  EditorTrackAudioTrackSegmentPreviewViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/3/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackAudioTrackSegmentPreviewViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (nullable instancetype)initWithAVCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment;
@end

NS_ASSUME_NONNULL_END
