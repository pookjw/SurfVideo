//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorTrackViewModel.hpp"
#import "constants.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackViewModel ()
@property (retain, nonatomic) EditorViewModel *editorViewModel;
@property (retain, nonatomic) UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *dataSource;
@property (retain, nonatomic) dispatch_queue_t queue;
@end

@implementation EditorTrackViewModel

- (instancetype)initWithEditorViewModel:(EditorViewModel *)editorViewModel dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *)dataSource {
    if (self = [super init]) {
        _editorViewModel = [editorViewModel retain];
        _dataSource = [dataSource retain];
        [self commomInit_EditorTrackViewModel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self 
                                                  name:EditorViewModelDidChangeCompositionNotification
                                                object:_editorViewModel];
    [_editorViewModel release];
    [_dataSource release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [super dealloc];
}

- (void)commomInit_EditorTrackViewModel __attribute__((objc_direct)) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorTrackViewModel", attr);
    _queue = queue;
    
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    operationQueue.underlyingQueue = queue;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:) 
                                               name:EditorViewModelDidChangeCompositionNotification
                                             object:_editorViewModel];
    
    [operationQueue release];
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^ _Nullable)(NSError * _Nullable))completionHandler {
    dispatch_async(_queue, ^{
        auto returnNOModelError = ^{
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
        };
        
        auto sectionModel = [_dataSource sectionIdentifierForIndex:indexPath.section];
        if (!sectionModel) {
            returnNOModelError();
            NS_VOIDRETURN;
        }
        
        auto trackIDNumber = static_cast<NSNumber *>(sectionModel.userInfo[EditorTrackSectionModelTrackIDKey]);
        if (trackIDNumber == nil) {
            returnNOModelError();
            NS_VOIDRETURN;
        }
        
        CMPersistentTrackID trackID = trackIDNumber.intValue;
        
        auto itemModel = [_dataSource itemIdentifierForIndexPath:indexPath];
        if (!itemModel) {
            returnNOModelError();
            NS_VOIDRETURN;
        }
        
        auto trackSegment = static_cast<AVCompositionTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        if (!trackSegment) {
            returnNOModelError();
            NS_VOIDRETURN;
        }
        
        //
        
        [_editorViewModel removeTrackSegment:trackSegment atTrackID:trackID completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    });
}

- (void)unsafe_compositionDidUpdate:(AVComposition *)composition __attribute__((objc_direct)) {
    AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:EditorViewModel.mainVideoTrackID];
    assert(mainVideoTrack);
    
    //
    
    auto snapshot = [NSDiffableDataSourceSnapshot<EditorTrackSectionModel *, EditorTrackItemModel *> new];
    
    auto sectionModel = [[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeMainVideoTrack];
    sectionModel.userInfo = @{EditorTrackSectionModelTrackIDKey: @(EditorViewModel.mainVideoTrackID)};
    [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
    
    auto itemModels = [NSMutableArray<EditorTrackItemModel *> new];
    for (AVCompositionTrackSegment *segment in mainVideoTrack.segments) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeMainVideoTrackSegment];
        itemModel.userInfo = @{EditorTrackItemModelCompositionTrackSegmentKey: segment};
        [itemModels addObject:itemModel];
        [itemModel release];
        
        [pool release];
    }
    
    [snapshot appendItemsWithIdentifiers:itemModels intoSectionWithIdentifier:sectionModel];
    [sectionModel release];
    [itemModels release];
    
    [_dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
    [snapshot release];
}

- (void)compositionDidChange:(NSNotification *)noitification {
    [self unsafe_compositionDidUpdate:noitification.userInfo[EditorViewModelDidChangeCompositionKey]];
}

@end
