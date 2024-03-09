//
//  AudioWaveformView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface AudioWaveformView : UIView
@property (copy, nonatomic, setter=setAVAsset:) AVAsset *avAsset;
@property (copy, nonatomic) UIColor *waveformColor;
@end

NS_ASSUME_NONNULL_END
