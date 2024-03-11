//
//  SettingsViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import <UIKit/UIKit.h>
#import "SettingsSectionModel.hpp"
#import "SettingsItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SettingsViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<SettingsSectionModel *, SettingsItemModel *> *)dataSource;
- (void)loadDataSourceWithCompletionHandler:(void (^ _Nullable)())completionHandler;
- (void)itemModelFromIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(SettingsItemModel * _Nullable itemModel))completionHandler;
- (SettingsSectionModel * _Nullable)queue_sectionModelAtIndex:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
