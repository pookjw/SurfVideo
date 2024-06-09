//
//  UICollectionView+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionView (Private)
- (void)_deselectAllAnimated:(BOOL)arg1 notifyDelegate:(BOOL)arg2;
- (void)_deselectItemAtIndexPath:(NSIndexPath *)arg1 animated:(BOOL)arg2 notifyDelegate:(BOOL)arg3;
- (void)_selectItemAtIndexPath:(NSIndexPath *)arg1 animated:(BOOL)arg2 scrollPosition:(UICollectionViewScrollPosition)arg3 notifyDelegate:(BOOL)arg4;
- (void)_selectItemAtIndexPath:(id)arg1 animated:(BOOL)arg2 scrollPosition:(UICollectionViewScrollPosition)arg3 notifyDelegate:(BOOL)arg4 deselectPrevious:(BOOL)arg5;
@end

NS_ASSUME_NONNULL_END
