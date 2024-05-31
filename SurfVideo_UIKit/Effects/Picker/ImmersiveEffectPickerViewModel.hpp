//
//  ImmersiveEffectPickerViewModel.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <UIKit/UIKit.h>
#import "ImmersiveEffectPickerItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ImmersiveEffectPickerViewModel : NSObject
@property (retain, readonly, nonatomic) UICollectionViewDiffableDataSource<NSNull *,ImmersiveEffectPickerItemModel *> *dataSource;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *, ImmersiveEffectPickerItemModel *> *)dataSource;
- (void)loadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;
- (void)postSelectedEffectNotificationAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
