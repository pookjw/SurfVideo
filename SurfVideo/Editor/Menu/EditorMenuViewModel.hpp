//
//  EditorMenuViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <UIKit/UIKit.h>
#import "EditorService.hpp"
#import "EditorMenuSectionModel.hpp"
#import "EditorMenuItemModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorMenuViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(EditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
- (void)updateDataSourceWithSelectedTrackItemModel:(EditorTrackItemModel * _Nullable)selectedTrackItemModel;
- (void)itemModelFromIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorMenuItemModel * _Nullable itemModel))completionHandler;
@end

NS_ASSUME_NONNULL_END
