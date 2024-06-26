//
//  EditorMenuViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <UIKit/UIKit.h>
#import <SurfVideoCore/SVEditorService.hpp>
#import "EditorMenuSectionModel.hpp"
#import "EditorMenuItemModel.hpp"
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorMenuViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(SVEditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
- (void)loadDataSourceWithCompletionHandler:(void (^ _Nullable)())completionHandler;
- (void)itemModelFromIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorMenuItemModel * _Nullable itemModel))completionHandler;
@end

NS_ASSUME_NONNULL_END

#endif
