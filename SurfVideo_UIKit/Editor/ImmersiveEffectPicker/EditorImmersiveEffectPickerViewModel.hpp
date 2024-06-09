//
//  EditorImmersiveEffectPickerViewModel.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "EditorImmersiveEffectPickerItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectPickerViewModel : NSObject
@property (retain, readonly, nonatomic) UICollectionViewDiffableDataSource<NSNull *,EditorImmersiveEffectPickerItemModel *> *dataSource;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *, EditorImmersiveEffectPickerItemModel *> *)dataSource;
- (void)loadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;
- (EditorImmersiveEffectPickerItemModel * _Nullable)itemModelAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END

#endif
