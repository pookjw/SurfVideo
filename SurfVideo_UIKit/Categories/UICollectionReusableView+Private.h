//
//  UICollectionReusableView+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionReusableView ()
@property (weak, nonatomic, getter=_collectionView, setter=_setCollectionView:) UICollectionView *collectionView;
@end

NS_ASSUME_NONNULL_END
