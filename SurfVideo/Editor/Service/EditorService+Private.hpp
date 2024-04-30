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
@property (copy, nonatomic, setter=queue_setTrackSegmentNames:) NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *queue_trackSegmentNames;
@property (copy, nonatomic, setter=queue_setCompositionIDs:) NSDictionary<NSNumber *, NSArray<NSUUID *> *> *queue_compositionIDs;

- (void)queue_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler;
- (void)queue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error))completionHandler;

- (void)queue_appendClipsToTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error))completionHandler;
- (void)queue_appendClipsToTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error))completionHandler;
- (void)queue_appendClipsToTrackFromURLs:(NSArray<NSURL *> *)sourceURLs trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSURL *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error))completionHandler;
- (BOOL)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets trackID:(CMPersistentTrackID)trackID progress:(NSProgress *)progress progressUnit:(int64_t)progressUnit mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError **)error;

- (void)queue_removeTrackSegment:(AVCompositionTrackSegment *)trackSegment trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable))completionHandler __deprecated;

- (NSArray<__kindof EditorRenderElement *> *)contextQueue_renderElementsFromVideoProject:(SVVideoProject *)videoProject;
- (void)contextQueue_videoCompositionAndRenderElementsFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error))completionHandler;
- (NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)contextQueue_trackSegmentNamesFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject;
- (void)contextQueue_finalizeWithComposition:(AVComposition *)composition compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements videoProject:(SVVideoProject *)videoProject completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)queue_postCompositionDidChangeNotification;

- (NSProgress *)exportToURLWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completionHandler;

- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)appendingCompositionIDArray:(NSArray<NSUUID *> *)addingComposittionIDArray trackID:(CMPersistentTrackID)trackID intoCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs;
- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)deletingCompositionIDArray:(NSArray<NSUUID *> *)deletingComposittionIDArray fromCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs;


@end

NS_ASSUME_NONNULL_END
