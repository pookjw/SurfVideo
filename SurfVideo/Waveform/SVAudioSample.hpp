//
//  SVAudioSample.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/8/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVAudioSample : NSManagedObject
@property (retain, nonatomic) NSData * _Nullable sha1;
@property (nonatomic) float noiseFloor;
@property (nonatomic) float maxSample;
@property (retain, nonatomic) NSArray *samples;
@property (nonatomic) float samplingRate;
@end

NS_ASSUME_NONNULL_END
