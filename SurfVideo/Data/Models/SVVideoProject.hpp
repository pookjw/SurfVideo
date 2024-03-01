//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVVideoTrack;
@class SVAudioTrack;
@class SVCaptionTrack;

@interface SVVideoProject : NSManagedObject
@property (copy, nonatomic) NSDate * _Nullable createdDate;
@property (retain, nonatomic) SVVideoTrack * _Nullable videoTrack;
@property (retain, nonatomic) SVAudioTrack * _Nullable audioTrack;
@property (retain, nonatomic) SVCaptionTrack * _Nullable captionTrack;
@end

NS_ASSUME_NONNULL_END
