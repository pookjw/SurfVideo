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

// AVVideoComposition *
extern NSString * const EditorServiceVideoCompositionKey;

// NSArray<__kindof EditorRenderElement *> *
extern NSString * const EditorServiceRenderElementsKey;

#define EditorServiceCompletionHandler void (^ _Nullable)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error)

__attribute__((objc_direct_members))
@interface EditorService : NSObject {
    @private dispatch_queue_t _queue;
    @private SVVideoProject *_queue_videoProject;
    @private NSSet<NSUserActivity *> *_userActivities;
    @private AVComposition *_queue_composition;
    @private AVVideoComposition *_queue_videoComposition;
    @private NSArray<__kindof EditorRenderElement *> *_queue_renderElements;
}
@property (readonly, nonatomic) CMPersistentTrackID mainVideoTrackID;
@property (readonly, nonatomic) CMPersistentTrackID audioTrackID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities NS_DESIGNATED_INITIALIZER;

- (void)compositionWithCompletionHandler:(void (^)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements))completionHandler;

- (void)initializeWithProgressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;

- (void)removeTrackSegment:(AVCompositionTrackSegment *)trackSegment atTrackID:(CMPersistentTrackID)trackID completionHandler:(EditorServiceCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
