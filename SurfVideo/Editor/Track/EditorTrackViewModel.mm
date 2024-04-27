//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorTrackViewModel.hpp"
#import "EditorService+VideoClip.hpp"
#import "EditorService+AudioClip.hpp"
#import "EditorService+Caption.hpp"
#import "constants.hpp"

namespace ns_EditorTrackViewModel {
    void *compositionContext = &compositionContext;
}

__attribute__((objc_direct_members))
@interface EditorTrackViewModel ()
@property (assign, atomic) CMTime durationTime;
@property (retain, nonatomic, readonly) EditorService *editorService;
@property (retain, nonatomic, readonly) UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *dataSource;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation EditorTrackViewModel

- (instancetype)initWithEditorService:(EditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *)dataSource {
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
        auto trackSegment = static_cast<AVCompositionTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        if (!trackSegment) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
            return;
        }
        
        //
        
        switch (itemModel.type) {
            case EditorTrackItemModelTypeVideoTrackSegment:
                [self.editorService removeVideoClipTrackSegment:trackSegment completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable error) {
                    completionHandler(error);
                }];
                break;
            case EditorTrackItemModelTypeAudioTrackSegment:
                [self.editorService removeAudioClipTrackSegment:trackSegment completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable error) {
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
        auto renderCaption = static_cast<EditorRenderCaption *>(itemModel.userInfo[EditorTrackItemModelRenderCaptionKey]);
        if (!renderCaption) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
            return;
        }
        
        [self.editorService removeCaption:renderCaption completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable error) {
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
    return [self.dataSource sectionIdentifierForIndex:index];
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
    [self.editorService editCaption:itemModel.userInfo[EditorTrackItemModelRenderCaptionKey] attributedString:attributedString startTime:kCMTimeInvalid endTime:kCMTimeInvalid completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    EditorRenderCaption *caption = itemModel.userInfo[EditorTrackItemModelRenderCaptionKey];
    
    [self.editorService editCaption:caption attributedString:caption.attributedString startTime:startTime endTime:endTime completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)queue_compositionDidUpdate:(AVComposition * _Nullable)composition 
                    renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements 
                 trackSegmentNames:(NSDictionary<NSNumber *, NSArray *> *)trackSegmentNames __attribute__((objc_direct)) {
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
        
        auto videoTrackSegmentItemModels = [[NSMutableArray<EditorTrackItemModel *> alloc] initWithCapacity:mainVideoTrack.segments.count];
        
        [mainVideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
            EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeVideoTrackSegment];
            
            auto userInfo = [NSMutableDictionary<NSString *, id> new];
            
            userInfo[EditorTrackItemModelCompositionTrackSegmentKey] = segment;
            
            if (id name = trackSegmentNames[@(self.editorService.mainVideoTrackID)][idx]) {
                if ([name isKindOfClass:NSString.class]) {
                    userInfo[EditorTrackItemModelTrackSegmentNameKey] = name;
                }
            }
            itemModel.userInfo = userInfo;
            [userInfo release];
            
            [videoTrackSegmentItemModels addObject:itemModel];
            [itemModel release];
        }];
        
        [snapshot appendItemsWithIdentifiers:videoTrackSegmentItemModels intoSectionWithIdentifier:mainVideoTrackSectionModel];
        [videoTrackSegmentItemModels release];
    }
    
    //
    
    AVCompositionTrack *audioTrack = [composition trackWithTrackID:self.editorService.audioTrackID];
    if (audioTrack.segments.count > 0) {
        EditorTrackSectionModel *audioTrackSectionModel = [EditorTrackSectionModel audioTrackSectionModelWithComposition:composition compositionTrack:audioTrack];
        [snapshot appendSectionsWithIdentifiers:@[audioTrackSectionModel]];
        
        auto audioTrackSegmentItemModels = [[NSMutableArray<EditorTrackItemModel *> alloc] initWithCapacity:audioTrack.segments.count];
        
        [audioTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
            EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeAudioTrackSegment];
            
            auto userInfo = [NSMutableDictionary<NSString *, id> new];
            
            userInfo[EditorTrackItemModelCompositionTrackSegmentKey] = segment;
            
            if (id name = trackSegmentNames[@(self.editorService.audioTrackID)][idx]) {
                if ([name isKindOfClass:NSString.class]) {
                    userInfo[EditorTrackItemModelTrackSegmentNameKey] = name;
                }
            }
            itemModel.userInfo = userInfo;
            [userInfo release];
            
            [audioTrackSegmentItemModels addObject:itemModel];
            [itemModel release];
        }];
        
        [snapshot appendItemsWithIdentifiers:audioTrackSegmentItemModels intoSectionWithIdentifier:audioTrackSectionModel];
        [audioTrackSegmentItemModels release];
    }
    
    //
    
    if (renderElements.count > 0) {
        EditorTrackSectionModel *captionTrackSectionModel = [EditorTrackSectionModel captionTrackSectionModelWithComposition:composition];
        [snapshot appendSectionsWithIdentifiers:@[captionTrackSectionModel]];
        
        auto captionItemModels = [NSMutableArray<EditorTrackItemModel *> new];
        for (__kindof EditorRenderElement *renderElement in renderElements) {
            EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeCaption];
            itemModel.userInfo = @{
                EditorTrackItemModelRenderCaptionKey: renderElement
            };
            [captionItemModels addObject:itemModel];
            [itemModel release];
        }
        
        [snapshot appendItemsWithIdentifiers:captionItemModels intoSectionWithIdentifier:captionTrackSectionModel];
        [captionItemModels release];
    }
    
    //
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
    [snapshot release];
}

- (void)compositionDidChange:(NSNotification *)noitification {
    dispatch_async(self.queue, ^{
        AVComposition *composition = noitification.userInfo[EditorServiceCompositionKey];
        NSArray<__kindof EditorRenderElement *> *renderElements = noitification.userInfo[EditorServiceRenderElementsKey];
        NSDictionary<NSNumber *, NSArray *> *trackSegmentNames = noitification.userInfo[EditorServiceTrackSegmentNamesKey];
        
        self.durationTime = composition.duration;
        [self queue_compositionDidUpdate:composition
                          renderElements:renderElements
                       trackSegmentNames:trackSegmentNames];
    });
}

@end
