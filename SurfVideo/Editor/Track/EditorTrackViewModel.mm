//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorTrackViewModel.hpp"
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

- (void)removeVideoTrackSegmentWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto trackSegment = static_cast<AVCompositionTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        if (!trackSegment) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
            return;
        }
        
        //
        
        [self.editorService removeTrackSegment:trackSegment atTrackID:trackSegment.sourceTrackID completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
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
        
        [self.editorService removeCaption:renderCaption completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
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
    [self.editorService editCaption:itemModel.userInfo[EditorTrackItemModelRenderCaptionKey] attributedString:attributedString startTime:kCMTimeInvalid endTime:kCMTimeInvalid completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    EditorRenderCaption *caption = itemModel.userInfo[EditorTrackItemModelRenderCaptionKey];
    
    [self.editorService editCaption:caption attributedString:caption.attributedString startTime:startTime endTime:endTime completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)queue_compositionDidUpdate:(AVComposition * _Nullable)composition renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements __attribute__((objc_direct)) {
    auto snapshot = [NSDiffableDataSourceSnapshot<EditorTrackSectionModel *, EditorTrackItemModel *> new];
    
    if (composition == nil) {
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
        [snapshot release];
        return;
    }
    
    //
    
    AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:self.editorService.mainVideoTrackID];
    assert(mainVideoTrack);
    
    EditorTrackSectionModel *mainVideoTrackSectionModel = [[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeMainVideoTrack];
    mainVideoTrackSectionModel.userInfo = @{EditorTrackSectionModelCompositionTrackKey: mainVideoTrack};
    [snapshot appendSectionsWithIdentifiers:@[mainVideoTrackSectionModel]];
    
    auto videoTrackSegmentItemModels = [NSMutableArray<EditorTrackItemModel *> new];
    for (AVCompositionTrackSegment *segment in mainVideoTrack.segments) {
        EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeVideoTrackSegment];
        itemModel.userInfo = @{
            EditorTrackItemModelCompositionTrackSegmentKey: segment
        };
        [videoTrackSegmentItemModels addObject:itemModel];
        [itemModel release];
    }
    
    [snapshot appendItemsWithIdentifiers:videoTrackSegmentItemModels intoSectionWithIdentifier:mainVideoTrackSectionModel];
    [mainVideoTrackSectionModel release];
    [videoTrackSegmentItemModels release];
    
    //
    
    if (renderElements.count > 0) {
        EditorTrackSectionModel *captionTrackSectionModel = [[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeCaptionTrack];
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
        [captionTrackSectionModel release];
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
        
        self.durationTime = composition.duration;
        [self queue_compositionDidUpdate:composition
                          renderElements:renderElements];
    });
}

@end
