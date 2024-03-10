//
//  EditorService+Private.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService.hpp"
#import "EditorRenderCaption.hpp"
#import <PhotosUI/PhotosUI.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorService (Private)
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, nonatomic, setter=queue_setVideoProject:) SVVideoProject *queue_videoProject;
@property (copy, readonly, nonatomic) NSSet<NSUserActivity *> *userActivities;
@property (copy, nonatomic, setter=queue_setComposition:) AVComposition *queue_composition;
@property (copy, nonatomic, setter=queue_setVideoComposition:) AVVideoComposition *queue_videoComposition;
@property (copy, nonatomic, setter=queue_setRenderElements:) NSArray<__kindof EditorRenderElement *> *queue_renderElements;
@property (copy, nonatomic, setter=queue_setTrackSegmentNames:) NSDictionary<NSNumber *, NSArray *> *queue_trackSegmentNames;

- (void)queue_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler;
- (void)queue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler;

- (void)appendClipsToTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler;
- (void)queue_appendClipsToTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler;
- (void)queue_appendClipsToTrackFromURLs:(NSArray<NSURL *> *)URLs trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler;
- (BOOL)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets trackID:(CMPersistentTrackID)trackID progress:(NSProgress *)progress progressUnit:(int64_t)progressUnit mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError **)error;

- (void)queue_removeTrackSegment:(AVCompositionTrackSegment *)trackSegment trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable))completionHandler;

- (NSArray<__kindof EditorRenderElement *> *)contextQueue_renderElementsFromVideoProject:(SVVideoProject *)videoProject;
- (void)contextQueue_videoCompositionAndRenderElementsFromComposition:(AVComposition *)composition
                                                    completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error))completionHandler;
- (NSDictionary<NSNumber * /* trackID */, NSArray * /* NSString or NSNull */> *)contextQueue_trackSegmentNamesFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject;
- (void)contextQueue_finalizeWithComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)queue_postCompositionDidChangeNotification;

- (NSProgress *)exportToURLWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
