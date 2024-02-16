//
//  NSCollectionLayoutItem+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/16/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCollectionLayoutItem (Private)
+ (instancetype)itemWithSize:(NSCollectionLayoutSize *)size decorationItems:(NSArray<NSCollectionLayoutDecorationItem *> *)decorationItems;
@end

NS_ASSUME_NONNULL_END
