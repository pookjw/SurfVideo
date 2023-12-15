//
//  SVVideoClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <CoreData/CoreData.h>
#import "SVClip.hpp"

NS_ASSUME_NONNULL_BEGIN

@class SVVideoTrack;

@interface SVVideoClip : SVClip
@property (retain, nonatomic) SVVideoTrack * _Nullable videoTrack;
@end

NS_ASSUME_NONNULL_END
