//
//  EditorPlayerViewVisualProvider.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/7/24.
//

#import <AVFoundation/AVFoundation.h>
#import "EditorPlayerViewController.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface EditorPlayerViewVisualProvider : NSObject
@property (readonly, nonatomic, direct) EditorPlayerViewController * _Nullable playerViewController;
@property (retain, nonatomic) AVPlayer * _Nullable player;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlayerViewController:(EditorPlayerViewController *)playerViewController NS_DESIGNATED_INITIALIZER;
- (void)playerViewController_viewDidLoad;
- (void)playerCurrentTimeDidChange:(CMTime)currentTime;
@end

NS_ASSUME_NONNULL_END
