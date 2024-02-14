//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorTrackViewModel.hpp"
#import "constants.hpp"

namespace ns_EditorTrackViewModel {
    void *compositionContext = &compositionContext;
}

__attribute__((objc_direct_members))
@interface EditorTrackViewModel ()
@property (retain, nonatomic, readonly) EditorService *editorViewModel;
@property (retain, nonatomic, readonly) UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *dataSource;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation EditorTrackViewModel

@synthesize queue = _queue;

- (instancetype)initWithEditorViewModel:(EditorService *)editorViewModel dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *,EditorTrackItemModel *> *)dataSource {
    if (self = [super init]) {
        _editorViewModel = [editorViewModel retain];
        _dataSource = [dataSource retain];
        [self commomInit_EditorTrackViewModel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self 
                                                  name:EditorServiceDidChangeCompositionNotification
                                                object:_editorViewModel];
    [_editorViewModel release];
    [_dataSource release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [super dealloc];
}

- (void)commomInit_EditorTrackViewModel __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:) 
                                               name:EditorServiceDidChangeCompositionNotification
                                             object:_editorViewModel];
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^ _Nullable)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto returnNOModelError = ^{
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain
                                                  code:SurfVideoNoModelFoundError
                                              userInfo:nil]);
        };
        
        auto itemModel = [self.dataSource itemIdentifierForIndexPath:indexPath];
        if (!itemModel) {
            returnNOModelError();
            return;
        }
        
        auto trackSegment = static_cast<AVCompositionTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        if (!trackSegment) {
            returnNOModelError();
            return;
        }
        
        //
        
        [_editorViewModel removeTrackSegment:trackSegment atTrackID:trackSegment.sourceTrackID completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
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

- (void)queue_compositionDidUpdate:(AVComposition * _Nullable)composition __attribute__((objc_direct)) {
    auto snapshot = [NSDiffableDataSourceSnapshot<EditorTrackSectionModel *, EditorTrackItemModel *> new];
    
    if (composition == nil) {
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
        [snapshot release];
        return;
    }
    
    AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:EditorService.mainVideoTrackID];
    assert(mainVideoTrack);
    
    auto sectionModel = [[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeMainVideoTrack];
    sectionModel.userInfo = @{EditorTrackSectionModelCompositionTrackKey: mainVideoTrack};
    [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
    
    auto itemModels = [NSMutableArray<EditorTrackItemModel *> new];
    for (AVCompositionTrackSegment *segment in mainVideoTrack.segments) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        EditorTrackItemModel *itemModel = [[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeMainVideoTrackSegment];
        itemModel.userInfo = @{
            EditorTrackItemModelCompositionTrackSegmentKey: segment
        };
        [itemModels addObject:itemModel];
        [itemModel release];
        
        [pool release];
    }
    
    [snapshot appendItemsWithIdentifiers:itemModels intoSectionWithIdentifier:sectionModel];
    [sectionModel release];
    [itemModels release];
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
    [snapshot release];
}

- (void)compositionDidChange:(NSNotification *)noitification {
    dispatch_async(self.queue, ^{
        [self queue_compositionDidUpdate:noitification.userInfo[EditorServiceDidChangeCompositionKey]];
    });
}

- (dispatch_queue_t)queue {
    if (auto queue = _queue) return queue;
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorTrackViewModel", attr);
    
    dispatch_retain(queue);
    _queue = queue;
    
    return [queue autorelease];
}

@end
