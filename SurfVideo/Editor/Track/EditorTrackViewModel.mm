//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewModel.hpp"

EditorTrackViewModel::EditorTrackViewModel(std::shared_ptr<EditorViewModel> editorViewModel,
                                           UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *dataSource)
: _editorViewModel(editorViewModel), _dataSource([dataSource retain]) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorTrackViewModel", attr);
    _queue = queue;
}

EditorTrackViewModel::~EditorTrackViewModel() {
    dispatch_release(_queue);
    [_composition release];
    [_dataSource release];
}

void EditorTrackViewModel::updateComposition(std::shared_ptr<EditorTrackViewModel> ref,
                                             AVComposition * _Nullable composition,
                                             void (^ _Nullable completionHandler)()) {
    dispatch_async(ref.get()->_queue, ^{
        [_composition release];
        _composition = [composition copy];
        
        AVCompositionTrack * _Nullable mainVideoTrack = [composition trackWithTrackID:EditorViewModel::mainVideoTrack()];
        if (!mainVideoTrack) {
            if (completionHandler) {
                completionHandler();
            }
            return;
        }
        
        //
        
        auto snapshot = [NSDiffableDataSourceSnapshot<EditorTrackSectionModel *, EditorTrackItemModel *> new];
        
        auto sectionModel = [[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeMainVideoTrack];
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
        
        [ref.get()->_dataSource applySnapshot:snapshot animatingDifferences:YES completion:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
        
        [snapshot release];
    });
}
