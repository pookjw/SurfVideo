//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorTrackViewModel.hpp"

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
    }
    
    return self;
}

- (void)dealloc {
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
}

- (void)unsafe_compositionDidUpdate:(AVComposition *)composition __attribute__((objc_direct)) {
    AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:_editorViewModel.mainVideoTrackID];
    assert(mainVideoTrack);
    
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
    
    [_dataSource applySnapshot:snapshot animatingDifferences:YES completion:nil];
    [snapshot release];
}

@end
