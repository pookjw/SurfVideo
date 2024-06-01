//
//  EditorImmersiveEffectPickerViewModel.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "EditorImmersiveEffectPickerViewModel.hpp"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectPickerViewModel ()
@end

@implementation EditorImmersiveEffectPickerViewModel

- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSNull *,EditorImmersiveEffectPickerItemModel *> *)dataSource {
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
    NSDiffableDataSourceSnapshot<NSNull *, EditorImmersiveEffectPickerItemModel *> *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [snapshot appendSectionsWithIdentifiers:@[[NSNull null]]];
    
    NSUInteger allEffectsCount;
    const ImmersiveEffect *allEffects = allImmersiveEffects(&allEffectsCount);
    
    NSMutableArray<EditorImmersiveEffectPickerItemModel *> *allItemModels = [[NSMutableArray alloc] initWithCapacity:allEffectsCount];
    
    for (NSUInteger index = 0; index < allEffectsCount; index++) {
        EditorImmersiveEffectPickerItemModel *itemModel = [[EditorImmersiveEffectPickerItemModel alloc] initWithEffect:allEffects[index]];
        
        [allItemModels addObject:itemModel];
        [itemModel release];
    }
    
    [snapshot appendItemsWithIdentifiers:allItemModels intoSectionWithIdentifier:[NSNull null]];
    [allItemModels release];
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES completion:completionHandler];
    [snapshot release];
}

- (EditorImmersiveEffectPickerItemModel *)itemModelAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource itemIdentifierForIndexPath:indexPath];
}

@end

#endif
