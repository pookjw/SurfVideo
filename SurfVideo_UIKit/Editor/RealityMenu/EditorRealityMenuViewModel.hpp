//
//  EditorRealityMenuViewModel.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <UIKit/UIKit.h>
#import "EditorRealityMenuItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorRealityMenuViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *, EditorRealityMenuItemModel *> *)dataSource;
- (void)loadDataSourceWithCompletionHandler:(void (^ _Nullable)())completionHandler;
- (void)didChangeSelectedItemsForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
- (EditorRealityMenuItemModel * _Nullable)itemModelForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath * _Nullable)indexPathForItemType:(EditorRealityMenuItemModelType)itemType;
@end

NS_ASSUME_NONNULL_END
