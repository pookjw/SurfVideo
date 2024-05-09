//
//  EditorService+Private.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/EditorService.hpp>
#import <SurfVideoCore/EditorRenderCaption.hpp>
#import <PhotosUI/PhotosUI.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

// NSDictionary<NSURL *, NSUUID *> *
extern NSString * const EditorServicePrivateCreatedCompositionIDsBySourceURLKey;

// NSArray<NSUUID *> *
extern NSString * const EditorServicePrivateCreatedCompositionIDArrayKey;

// NSDictionary<NSURL *, NSURL *> *
extern NSString * const EditorServicePrivateCreatedFootageURLsBySourceURLKey;

// NSArray<NSURL *> *
extern NSString * const EditorServicePrivateCreatedFootageURLArrayKey;

// NSDictionary<NSURL *, NSString *> *
extern NSString * const EditorServicePrivateTitlesBySourceURLKey;

// NSDictionary<NSUUID *, NSString *> *
extern NSString * const EditorServicePrivateTitlesByCompositionIDKey;

// NSDictionary<NSString *, NSUUID *> *
extern NSString * const EditorServicePrivateCreatedCompositionIDsByAssetIdentifierKey;

// NSDictionary<NSUUID *, NSString *> *
extern NSString * const EditorServicePrivateTitlesByCompositionIDKey;

__attribute__((objc_direct_members))
@interface EditorService (Private)
@property (retain, readonly, nonatomic) dispatch_queue_t queue_1;
@property (retain, readonly, nonatomic) dispatch_queue_t queue_2;
@property (retain, nonatomic, setter=queue_setVideoProject:) SVVideoProject *queue_videoProject;
@property (copy, readonly, nonatomic) NSSet<NSUserActivity *> *userActivities;
@property (copy, nonatomic, setter=queue_setComposition:) AVComposition *queue_composition;
@property (copy, nonatomic, setter=queue_setVideoComposition:) AVVideoComposition *queue_videoComposition;
@property (copy, nonatomic, setter=queue_setRenderElements:) NSArray<__kindof EditorRenderElement *> *queue_renderElements;
@property (copy, nonatomic, setter=queue_setTackSegmentNamesByCompositionID:) NSDictionary<NSUUID *, NSString *> *queue_trackSegmentNamesByCompositionID;
@property (copy, nonatomic, setter=queue_setCompositionIDs:) NSDictionary<NSNumber *, NSArray<NSUUID *> *> *queue_compositionIDs;

- (void)assertQueue;

- (void)queue_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler;

- (void)contextQueue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error))completionHandler;

/*
 EditorServicePrivateCreatedCompositionIDsBySourceURLKey
 EditorServicePrivateCreatedCreatedCompositionIDArrayKey
 EditorServicePrivateCreatedFootageURLsBySourceURLKey
 EditorServicePrivateCreatedFootageURLArrayKey
 EditorServicePrivateTitlesBySourceURLKey
 EditorServicePrivateTitlesByCompositionIDKey
 */
- (NSDictionary<NSString *, id> * _Nullable)contextQueue_createSVClipsFromSourceURLs:(NSArray<NSURL *> *)sourceURLs videoProject:(SVVideoProject *)videoProject trackID:(CMPersistentTrackID)trackID error:(NSError **)error;

/*
 EditorServicePrivateCreatedCompositionIDsByAssetIdentifierKey
 EditorServicePrivateCreatedCompositionIDArrayKey
 EditorServicePrivateTitlesByCompositionIDKey
 */
- (NSDictionary<NSString *, id> * _Nullable)contextQueue_createSVClipsFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers titlesByAssetIdentifier:(NSDictionary<NSString *, NSString *> *)titlesByAssetIdentifier videoProject:(SVVideoProject *)videoProject trackID:(CMPersistentTrackID)trackID error:(NSError **)error;

- (AVMutableComposition * _Nullable)appendClipsToTrackFromURLs:(NSArray<NSURL *> *)urls trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError **)error;

- (AVMutableComposition * _Nullable)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets timeRangesByAVAsset:(NSDictionary<AVAsset *, NSValue *> * _Nullable)timeRangesByAVAsset trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError * _Nullable * _Nullable)error;

- (void)queue_removeTrackSegmentWithCompositionID:(NSUUID *)compositionID mutableComposition:(AVMutableComposition *)mutableComposition compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs trackSegmentNamesByCompositionID:(NSDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionID completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable))completionHandler;

- (NSArray<__kindof EditorRenderElement *> *)contextQueue_renderElementsFromVideoProject:(SVVideoProject *)videoProject;
- (void)contextQueue_videoCompositionAndRenderElementsFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error))completionHandler;

- (void)contextQueue_finalizeWithVideoProject:(SVVideoProject *)videoProject composition:(AVComposition *)composition compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs trackSegmentNamesByCompositionID:(NSDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionID renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)queue_postCompositionDidChangeNotification;

- (NSProgress *)exportToURLWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completionHandler;

- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)appendingCompositionIDArray:(NSArray<NSUUID *> *)addingComposittionIDArray trackID:(CMPersistentTrackID)trackID intoCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs;
- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)deletingCompositionIDArray:(NSArray<NSUUID *> *)deletingComposittionIDArray fromCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs;

- (void)appendClipsFromURLs:(NSArray<NSURL *> *)urls intoTrackID:(CMPersistentTrackID)trackID progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler;

- (NSArray<NSString *> *)assetIdentifiersFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults;
- (NSDictionary<AVAsset *, NSString *> *)titlesFromAVAssets:(NSArray<AVAsset *> *)avAssets;

- (NSDictionary<NSString *, NSString *> *)titlesByAssetIdentifierWithAVAssetsByAssetIdentifier:(NSDictionary<NSString *, AVAsset *> *)avAssetsByAssetIdentifier titlesByAVAsset:(NSDictionary<AVAsset *, NSString *> *)titlesByAVAsset;

@end

NS_ASSUME_NONNULL_END
