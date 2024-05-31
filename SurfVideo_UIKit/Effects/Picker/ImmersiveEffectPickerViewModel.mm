//
//  ImmersiveEffectPickerViewModel.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffectPickerViewModel.hpp"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface ImmersiveEffectPickerViewModel ()
@end

@implementation ImmersiveEffectPickerViewModel

- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *,ImmersiveEffectPickerItemModel *> *)dataSource {
    if (self = [super init]) {
        _dataSource = [dataSource retain];
    }
    
    return self;
}

- (void)dealloc {
    [_dataSource release];
    [super dealloc];
}

- (void)loadWithCompletionHandler:(void (^)())completionHandler {
    NSDiffableDataSourceSnapshot<NSNull *, ImmersiveEffectPickerItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [snapshot appendSectionsWithIdentifiers:@[[NSNull null]]];
    
    NSUInteger allEffectsCount;
    const ImmersiveEffect *allEffects = allImmersiveEffectTypes(&allEffectsCount);
    
    NSMutableArray<ImmersiveEffectPickerItemModel *> *allItemModels = [[NSMutableArray alloc] initWithCapacity:allEffectsCount];
    
    for (NSUInteger index = 0; index < allEffectsCount; index++) {
        ImmersiveEffectPickerItemModel *itemModel = [[ImmersiveEffectPickerItemModel alloc] initWithEffect:allEffects[index]];
        
        [allItemModels addObject:itemModel];
        [itemModel release];
    }
    
    [snapshot appendItemsWithIdentifiers:allItemModels intoSectionWithIdentifier:[NSNull null]];
    [allItemModels release];
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:completionHandler];
    [snapshot release];
}

- (void)postSelectedEffectNotificationAtIndexPath:(NSIndexPath *)indexPath {
    ImmersiveEffectPickerItemModel * _Nullable itemModel = [self.dataSource itemIdentifierForIndexPath:indexPath];
    
    if (itemModel == nil) return;
    
    [NSNotificationCenter.defaultCenter postNotificationName:ImmersiveEffectDidSelectEffectNotification
                                                      object:nil
                                                    userInfo:@{ImmersiveEffectSelectedEffectKey: @(itemModel.effect)}];
}

@end

#endif
