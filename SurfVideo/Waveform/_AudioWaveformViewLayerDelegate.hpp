//
//  _AudioWaveformViewLayerDelegate.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface _AudioWaveformViewLayerDelegate : NSObject <CALayerDelegate>
@property (class, readonly, nonatomic) void *waveformColorContextKey;
@property (class, readonly, nonatomic) void *samplesContextKey;
@end

NS_ASSUME_NONNULL_END
