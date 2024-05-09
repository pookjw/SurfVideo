//
//  SVAudioWaveformView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVAudioWaveformView : UIView
@property (copy, nonatomic, setter=setAVAsset:) AVAsset *avAsset;
@property (copy, nonatomic) UIColor *waveformColor;
@end

NS_ASSUME_NONNULL_END

#endif
