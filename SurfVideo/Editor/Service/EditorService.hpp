//
//  EditorService.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SVProjectsManager.hpp"
#import "EditorRenderer.hpp"
#import "EditorRenderCaption.hpp"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const EditorServiceCompositionDidChangeNotification;

// AVComposition *
extern NSString * const EditorServiceCompositionKey;

// NSDictionary<NSNumber *, NSArray<NSUUID *> *> * (TrackID, compositionIDs (Track Segments))
extern NSString * const EditorServiceCompositionIDsKey;

// AVVideoComposition *
extern NSString * const EditorServiceVideoCompositionKey;

// NSArray<__kindof EditorRenderElement *> *
extern NSString * const EditorServiceRenderElementsKey;

// NSDictionary<NSUUID *, NSString *> *
extern NSString * const EditorServiceTrackSegmentNamesByCompositionIDKey;

typedef NS_ENUM(NSUInteger, EditorServiceExportQuality) {
    EditorServiceExportQualityLow,
    EditorServiceExportQualityMedium,
    EditorServiceExportQualityHigh
};

#define EditorServiceCompletionHandler void (^ _Nullable)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error)
#define EditorServiceCompletionHandlerBlock ^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error)

__attribute__((objc_direct_members))
@interface EditorService : NSObject {
    @private dispatch_queue_t _queue_1;
    @private dispatch_queue_t _queue_2;
    @private SVVideoProject *_queue_videoProject;
    @private NSSet<NSUserActivity *> *_userActivities;
    @private AVComposition *_queue_composition;
    @private AVVideoComposition *_queue_videoComposition;
    @private NSArray<__kindof EditorRenderElement *> *_queue_renderElements;
    @private NSDictionary<NSUUID *, NSString *> *_queue_trackSegmentNamesByCompositionID;
    @private NSDictionary<NSNumber *, NSArray<NSUUID *> *> *_queue_compositionIDs;
}
@property (readonly, nonatomic) CMPersistentTrackID mainVideoTrackID;
@property (readonly, nonatomic) CMPersistentTrackID audioTrackID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities NS_DESIGNATED_INITIALIZER;

- (void)compositionWithCompletionHandler:(void (^)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements))completionHandler;

- (void)initializeWithProgressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;

- (NSProgress *)exportWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
