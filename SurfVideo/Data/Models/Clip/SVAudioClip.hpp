//
//  SVAudioClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import "SVClip.hpp"

NS_ASSUME_NONNULL_BEGIN

@class SVAudioTrack;

@interface SVAudioClip : SVClip
@property (copy, nonatomic) NSValue * _Nullable startTimeValue;
@property (copy, nonatomic) NSValue * _Nullable endTimeValue;
@property (retain, nonatomic) SVAudioTrack * _Nullable audioTrack;
@end

NS_ASSUME_NONNULL_END
