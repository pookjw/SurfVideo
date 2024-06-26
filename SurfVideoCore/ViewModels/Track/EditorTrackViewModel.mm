//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <SurfVideoCore/EditorTrackViewModel.hpp>
#import <SurfVideoCore/SVEditorService+VideoClip.hpp>
#import <SurfVideoCore/SVEditorService+AudioClip.hpp>
#import <SurfVideoCore/SVEditorService+Caption.hpp>
#import <SurfVideoCore/constants.hpp>
#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <SurfVideoCore/NSCollectionViewDiffableDataSource+Category.hpp>
#import <SurfVideoCore/NSCollectionViewDiffableDataSource+Private.h>
#endif

namespace ns_EditorTrackViewModel {
    void *compositionContext = &compositionContext;
}

__attribute__((objc_direct_members))
@interface EditorTrackViewModel ()
@property (assign, atomic) CMTime durationTime;
@property (retain, nonatomic, readonly) SVEditorService *editorService;
#if TARGET_OS_IPHONE
@property (retain, nonatomic, readonly) UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *dataSource;
#elif TARGET_OS_OSX
@property (retain, nonatomic, readonly) NSCollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *dataSource;
#endif
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation EditorTrackViewModel


#if TARGET_OS_IPHONE
- (instancetype)initWithEditorService:(SVEditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *)dataSource {
#elif TARGET_OS_OSX
    - (instancetype)initWithEditorService:(SVEditorService *)editorService dataSource:(NSCollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *)dataSource {
#endif
    if (self = [super init]) {
        _editorService = [editorService retain];
        _dataSource = [dataSource retain];
        [self commomInit_EditorTrackViewModel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self 
                                                  name:EditorServiceCompositionDidChangeNotification
                                                object:_editorService];
    [_editorService release];
    [_dataSource release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [super dealloc];
}

- (void)commomInit_EditorTrackViewModel __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:) 
                                               name:EditorServiceCompositionDidChangeNotification
                                             object:_editorService];
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    _queue = dispatch_queue_create("EditorTrackViewModel", attr);
}

- (void)removeTrackSegmentWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        NSUUID *compositionID = itemModel.compositionID;
        if (compositionID == nil) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
            return;
        }
        
        //
        
        switch (itemModel.type) {
            case EditorTrackItemModelTypeVideoTrackSegment:
                [self.editorService removeVideoClipWithCompositionID:compositionID completionHandler:EditorServiceCompletionHandlerBlock {
                    completionHandler(error);
                }];
                break;
            case EditorTrackItemModelTypeAudioTrackSegment:
                [self.editorService removeAudioClipWithCompositionID:compositionID completionHandler:EditorServiceCompletionHandlerBlock {
                    completionHandler(error);
                }];
                break;
            default:
                [NSException raise:NSInternalInconsistencyException format:@"Incorrect EditorTrackItemModelType: %lu", itemModel.type];
                break;
        }
    });
}

- (void)removeCaptionWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        SVEditorRenderCaption *renderCaption = itemModel.renderCaption;
        if (!renderCaption) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
            return;
        }
        
        [self.editorService removeCaption:renderCaption completionHandler:EditorServiceCompletionHandlerBlock {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    });
}

- (NSUInteger)queue_numberOfItemsAtSectionIndex:(NSUInteger)index {
    auto snapshot = self.dataSource.snapshot;
    return [snapshot numberOfItemsInSection:snapshot.sectionIdentifiers[index]];
}

- (EditorTrackSectionModel *)queue_sectionModelAtIndex:(NSInteger)index {
#if TARGET_OS_OSX
    return [self.dataSource sv_sectionIdentifierForIndex:index];
#else
    return [self.dataSource sectionIdentifierForIndex:index];
#endif
}

- (EditorTrackItemModel *)queue_itemModelAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource itemIdentifierForIndexPath:indexPath];
}

- (void)itemModelAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorTrackItemModel * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler([self queue_itemModelAtIndexPath:indexPath]);
    });
}

- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel attributedString:(NSAttributedString *)attributedString completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler {
    [self.editorService editCaption:itemModel.renderCaption attributedString:attributedString startTime:kCMTimeInvalid endTime:kCMTimeInvalid completionHandler:EditorServiceCompletionHandlerBlock {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    SVEditorRenderCaption *caption = itemModel.renderCaption;
    
    [self.editorService editCaption:caption attributedString:caption.attributedString startTime:startTime endTime:endTime completionHandler:EditorServiceCompletionHandlerBlock {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)trimVideoClipWithItemModel:(EditorTrackItemModel *)itemModel sourceTrimTimeRange:(CMTimeRange)sourceTrimTimeRange completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler {
    [self.editorService trimVideoClipWithCompositionID:itemModel.compositionID
                                        trimTimeRange:sourceTrimTimeRange
                                     completionHandler:EditorServiceCompletionHandlerBlock {
        if (completionHandler != nil) {
            completionHandler(error);
        }
    }];
}

- (void)queue_compositionDidUpdate:(AVComposition * _Nullable)composition
                  videoComposition:(AVVideoComposition *)videoComposition
                    compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs
                    renderElements:(NSArray<__kindof SVEditorRenderElement *> *)renderElements 
trackSegmentNamesByCompositionIDKey:(NSDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionIDKey __attribute__((objc_direct)) {
    auto snapshot = [NSDiffableDataSourceSnapshot<EditorTrackSectionModel *, EditorTrackItemModel *> new];
    
    if (composition == nil) {
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
        [snapshot release];
        return;
    }
    
    //
    
    AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:self.editorService.mainVideoTrackID];
    if (mainVideoTrack.segments.count > 0) {
        assert(![composition isKindOfClass:AVMutableComposition.class]);
        EditorTrackSectionModel *mainVideoTrackSectionModel = [EditorTrackSectionModel mainVideoTrackSectionModelWithComposition:composition compositionTrack:mainVideoTrack];
        [snapshot appendSectionsWithIdentifiers:@[mainVideoTrackSectionModel]];
        
        CMPersistentTrackID mainVideoTrackID = self.editorService.mainVideoTrackID;
        NSArray<NSUUID *> *compositionIDArray = compositionIDs[@(mainVideoTrackID)];
        NSMutableArray<EditorTrackItemModel *> *videoTrackSegmentItemModels = [[NSMutableArray alloc] initWithCapacity:mainVideoTrack.segments.count];
        
        [mainVideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull compositionTrackSegment, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUUID *compositionID = compositionIDArray[idx];
            NSString *compositionTrackSegmentName = trackSegmentNamesByCompositionIDKey[compositionID];
            
            EditorTrackItemModel *itemModel = [EditorTrackItemModel videoTrackSegmentItemModelWithCompositionTrackSegment:compositionTrackSegment
                                                                                                              composition:composition
                                                                                                            compositionID:compositionID
                                                                                              compositionTrackSegmentName:compositionTrackSegmentName];
            
            [videoTrackSegmentItemModels addObject:itemModel];
        }];
        
        [snapshot appendItemsWithIdentifiers:videoTrackSegmentItemModels intoSectionWithIdentifier:mainVideoTrackSectionModel];
        [videoTrackSegmentItemModels release];
    }
    
    //
    
    AVCompositionTrack *audioTrack = [composition trackWithTrackID:self.editorService.audioTrackID];
    if (audioTrack.segments.count > 0) {
        EditorTrackSectionModel *audioTrackSectionModel = [EditorTrackSectionModel audioTrackSectionModelWithComposition:composition compositionTrack:audioTrack];
        [snapshot appendSectionsWithIdentifiers:@[audioTrackSectionModel]];
        
        CMPersistentTrackID audioTrackID = self.editorService.audioTrackID;
        NSArray<NSUUID *> *compositionIDArray = compositionIDs[@(audioTrackID)];
        NSMutableArray<EditorTrackItemModel *> *audioTrackSegmentItemModels = [[NSMutableArray alloc] initWithCapacity:audioTrack.segments.count];
        
        [audioTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull compositionTrackSegment, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUUID *compositionID = compositionIDArray[idx];
            NSString *compositionTrackSegmentName = trackSegmentNamesByCompositionIDKey[compositionID];
            
            EditorTrackItemModel *itemModel = [EditorTrackItemModel audioTrackSegmentItemModelWithCompositionTrackSegment:compositionTrackSegment
                                                                                                              composition:composition
                                                                                                            compositionID:compositionID
                                                                                              compositionTrackSegmentName:compositionTrackSegmentName];
            
            [audioTrackSegmentItemModels addObject:itemModel];
        }];
        
        [snapshot appendItemsWithIdentifiers:audioTrackSegmentItemModels intoSectionWithIdentifier:audioTrackSectionModel];
        [audioTrackSegmentItemModels release];
    }
    
    //
    
    NSPredicate *renderCaptionsPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:SVEditorRenderCaption.class];
    }];
    
    NSArray<SVEditorRenderCaption *> *renderCaptions = [renderElements filteredArrayUsingPredicate:renderCaptionsPredicate];
    
    if (renderCaptions.count > 0) {
        EditorTrackSectionModel *captionTrackSectionModel = [EditorTrackSectionModel captionTrackSectionModelWithComposition:composition];
        [snapshot appendSectionsWithIdentifiers:@[captionTrackSectionModel]];
        
        NSMutableArray<EditorTrackItemModel *> *captionItemModels = [[NSMutableArray alloc] initWithCapacity:renderCaptions.count];
        for (SVEditorRenderCaption *renderCaption in renderCaptions) {
            EditorTrackItemModel *itemModel = [EditorTrackItemModel captionItemModelWithRenderCaption:renderCaption 
                                                                                          composition:composition];
            [captionItemModels addObject:itemModel];
        }
        
        [snapshot appendItemsWithIdentifiers:captionItemModels intoSectionWithIdentifier:captionTrackSectionModel];
        [captionItemModels release];
    }
    
    //
    
    NSPredicate *renderEffectsPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:SVEditorRenderEffect.class];
    }];
    
    NSArray<SVEditorRenderEffect *> *renderEffects = [renderElements filteredArrayUsingPredicate:renderEffectsPredicate];
    
    if (renderEffects.count > 0) {
        EditorTrackSectionModel *effectTrackSectionModel = [EditorTrackSectionModel effectTrackSectionModelWithComposition:composition];
        [snapshot appendSectionsWithIdentifiers:@[effectTrackSectionModel]];
        
        NSMutableArray<EditorTrackItemModel *> *effectItemModels = [[NSMutableArray alloc] initWithCapacity:renderEffects.count];
        for (SVEditorRenderEffect *renderEffect in renderEffects) {
            EditorTrackItemModel *itemModel = [EditorTrackItemModel effectItemModelWithRenderEffect:renderEffect composition:composition];
            [effectItemModels addObject:itemModel];
        }
        
        [snapshot appendItemsWithIdentifiers:effectItemModels intoSectionWithIdentifier:effectTrackSectionModel];
        [effectItemModels release];
    }
    
    //
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
    [snapshot release];
}

- (void)compositionDidChange:(NSNotification *)noitification {
    dispatch_async(self.queue, ^{
        AVComposition *composition = noitification.userInfo[EditorServiceCompositionKey];
        AVVideoComposition *videoComposition = noitification.userInfo[EditorServiceVideoCompositionKey];
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = noitification.userInfo[EditorServiceCompositionIDsKey];
        NSArray<__kindof SVEditorRenderElement *> *renderElements = noitification.userInfo[EditorServiceRenderElementsKey];
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionIDKey = noitification.userInfo[EditorServiceTrackSegmentNamesByCompositionIDKey];
        
        self.durationTime = composition.duration;
        [self queue_compositionDidUpdate:composition
                        videoComposition:videoComposition
                          compositionIDs:compositionIDs
                          renderElements:renderElements
     trackSegmentNamesByCompositionIDKey:trackSegmentNamesByCompositionIDKey];
    });
}

@end
