//
//  NSCollectionLayoutSection+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/15/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCollectionLayoutSection (Private)
@property (nonatomic, getter=_cornerRadius, setter=_setCornerRadius:) CGFloat _cornerRadius;
@end

NS_ASSUME_NONNULL_END
