//
//  AudioSamplesExtractor.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/6/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface AudioSamplesExtractor : NSObject
// kCMTimeRangeInvalid, 0
+ (void)extractAudioSamplesFromAssetTrack:(AVAssetTrack *)assetTrack timeRange:(CMTimeRange)timeRange desiredNumberOfSamples:(NSUInteger)desiredNumberOfSamples completionHandler:(void (^)(NSArray<NSNumber *> * _Nullable samples, std::float_t maxSample, NSError * _Nullable error))completionHandler;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
