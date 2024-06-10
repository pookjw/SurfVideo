//
//  EditorRealityMenuViewModel.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import "EditorRealityMenuViewModel.hpp"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface EditorRealityMenuViewModel ()
@property (retain, nonatomic, readonly) UICollectionViewDiffableDataSource<NSNull *, EditorRealityMenuItemModel *> *dataSource;
@end

@implementation EditorRealityMenuViewModel

- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *,EditorRealityMenuItemModel *> *)dataSource {
    if (self = [super init]) {
        _dataSource = [dataSource retain];
    }
    
    return self;
}

- (void)dealloc {
    [_dataSource release];
    [super dealloc];
}

- (void)loadDataSourceWithCompletionHandler:(void (^)())completionHandler {
    NSDiffableDataSourceSnapshot<NSNull *, EditorRealityMenuItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [snapshot appendSectionsWithIdentifiers:@[[NSNull null]]];
    
    EditorRealityMenuItemModel *immersiveSpaceItemModel = [[EditorRealityMenuItemModel alloc] initWithType:EditorRealityMenuItemModelTypeImmersiveSpace];
    
    [snapshot appendItemsWithIdentifiers:@[immersiveSpaceItemModel] intoSectionWithIdentifier:[NSNull null]];
    
    [immersiveSpaceItemModel release];
    
    [_dataSource applySnapshot:snapshot animatingDifferences:YES completion:completionHandler];
    [snapshot release];
}

- (void)didChangeSelectedItemsForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    UICollectionViewDiffableDataSource *dataSource = _dataSource;
    
    BOOL shouldShowScrollingTrackViewWithHandTrackingItem = NO;
    
    for (NSIndexPath *indexPath in indexPaths) {
        EditorRealityMenuItemModel *itemModel = [dataSource itemIdentifierForIndexPath:indexPath];
        EditorRealityMenuItemModelType type = itemModel.type;
        

        switch (type) {
            case EditorRealityMenuItemModelTypeImmersiveSpace:
                shouldShowScrollingTrackViewWithHandTrackingItem = YES;
                break;
            default:
                break;
        }
    }
    
    if (shouldShowScrollingTrackViewWithHandTrackingItem) {
        BOOL hasScrollingTrackViewWithHandTrackingItem = NO;
        
        for (EditorRealityMenuItemModel *itemModel in dataSource.snapshot.itemIdentifiers) {
            if (itemModel.type == EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking) {
                hasScrollingTrackViewWithHandTrackingItem = YES;
                break;
            }
        }
        
        if (!hasScrollingTrackViewWithHandTrackingItem) {
            NSDiffableDataSourceSnapshot *snapshot = [dataSource.snapshot copy];
            
            EditorRealityMenuItemModel *itemModel = [[EditorRealityMenuItemModel alloc] initWithType:EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking];
            
            [snapshot appendItemsWithIdentifiers:@[itemModel]];
            [itemModel release];
            
            [dataSource applySnapshot:snapshot animatingDifferences:YES];
            [snapshot release];
        }
    } else {
        EditorRealityMenuItemModel * _Nullable itemModel = nil;
        
        for (EditorRealityMenuItemModel *_itemModel in dataSource.snapshot.itemIdentifiers) {
            if (_itemModel.type == EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking) {
                itemModel = _itemModel;
                break;
            }
        }
        
        if (itemModel != nil) {
            NSDiffableDataSourceSnapshot *snapshot = [dataSource.snapshot copy];
            
            [snapshot deleteItemsWithIdentifiers:@[itemModel]];
            
            [dataSource applySnapshot:snapshot animatingDifferences:YES];
            [snapshot release];
        }
    }
}

- (EditorRealityMenuItemModel *)itemModelForIndexPath:(NSIndexPath *)indexPath {
    return [_dataSource itemIdentifierForIndexPath:indexPath];
}

- (NSIndexPath *)indexPathForItemType:(EditorRealityMenuItemModelType)itemType {
    for (EditorRealityMenuItemModel *itemModel in _dataSource.snapshot.itemIdentifiers) {
        if (itemModel.type == itemType) {
            return [_dataSource indexPathForItemIdentifier:itemModel];
        }
    }
    
    return nil;
}

@end

#endif
