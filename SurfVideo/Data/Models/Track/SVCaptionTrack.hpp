//
//  SVCaptionTrack.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVCaption;
@class SVVideoProject;

@interface SVCaptionTrack : NSManagedObject
@property (retain, nonatomic) NSSet<SVCaption *> * _Nullable captions;
@property (retain, nonatomic) SVVideoProject * _Nullable videoProject;
- (void)addCaptionsObject:(SVCaption *)value;
- (void)removeCaptionsObject:(SVCaption *)value;
- (void)addCaptions:(NSSet<SVCaption *> *)values;
- (void)removeCaptions:(NSSet<SVCaption *> *)values;
@end

NS_ASSUME_NONNULL_END
