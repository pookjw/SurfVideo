//
//  EditorTrackViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EditorService.hpp"
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(EditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
- (void)removeAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSUInteger)queue_numberOfItemsAtSectionIndex:(NSUInteger)index;
- (EditorTrackSectionModel * _Nullable)queue_sectionModelAtIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)queue_itemModelAtIndexPath:(NSIndexPath *)indexPath;
- (void)itemModelAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorTrackItemModel * _Nullable itemModel))completionHandler;
@end

NS_ASSUME_NONNULL_END
