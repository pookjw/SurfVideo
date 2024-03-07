//
//  AudioSamplesExtractor.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/6/24.
//

#import <AVFoundation/AVFoundation.h>
#include <vector>
#include <optional>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface AudioSamplesExtractor : NSObject
// kCMTimeRangeInvalid, 0
+ (void)extractAudioSamplesFromAssetTrack:(AVAssetTrack *)assetTrack timeRange:(CMTimeRange)timeRange downsamplingRate:(Float64)downsamplingRate noiseFloor:(float)noiseFloor progressHandler:(void (^)(std::optional<std::vector<float>> samples, BOOL isFinal, BOOL *stop, NSError * _Nullable error))progressHandler;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
