//
//  EditorMenuViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import "EditorMenuViewModel.hpp"

__attribute__((objc_direct_members))
@interface EditorMenuViewModel ()
@property (retain, nonatomic, readonly) EditorService *editorService;
@property (retain, nonatomic, readonly) UICollectionViewDiffableDataSource<EditorMenuSectionModel *,EditorMenuItemModel *> *dataSource;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation EditorMenuViewModel

@synthesize queue = _queue;

- (instancetype)initWithEditorService:(EditorService *)editorService dataSource:(nonnull UICollectionViewDiffableDataSource<EditorMenuSectionModel *,EditorMenuItemModel *> *)dataSource {
    if (self = [super init]) {
        _editorService = [editorService retain];
        _dataSource = [dataSource retain];
    }
    
    return self;
}

- (void)dealloc {
    [_editorService release];
    [_dataSource release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [super dealloc];
}

- (void)loadDataSourceWithCompletionHandler:(void (^)())completionHandler {
    dispatch_async(self.queue, ^{
        auto snapshot = [NSDiffableDataSourceSnapshot<EditorMenuSectionModel *,EditorMenuItemModel *> new];
        
        EditorMenuSectionModel *sectionModel = [[EditorMenuSectionModel alloc] initWithType:EditorMenuSectionModelTypeMain];
        [snapshot appendSectionsWithIdentifiers:@[sectionModel]];
        
        EditorMenuItemModel *addCaptionItemModel = [[EditorMenuItemModel alloc] initWithType:EditorMenuItemModelTypeAddCaption];
        [snapshot appendItemsWithIdentifiers:@[addCaptionItemModel] intoSectionWithIdentifier:sectionModel];
        
        [sectionModel release];
        [addCaptionItemModel release];
        
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
        [snapshot release];
    });
}

- (void)itemModelFromIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorMenuItemModel * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler([self.dataSource itemIdentifierForIndexPath:indexPath]);
    });
}

- (dispatch_queue_t)queue {
    if (auto queue = _queue) return queue;
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorMenuViewModel", attr);
    
    dispatch_retain(queue);
    _queue = queue;
    
    return [queue autorelease];
}

@end
