//
//  NSCollectionLayoutDecorationItem+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/15/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCollectionLayoutDecorationItem (Private)
@property (nonatomic) BOOL isBackgroundDecoration;
@property (retain, nonatomic, setter=_setRegistrationViewClass:) Class _registrationViewClass;
+ (instancetype)decorationItemWithSize:(NSCollectionLayoutSize *)size elementKind:(NSString *)arg2 containerAnchor:(NSCollectionLayoutAnchor *)containerAnchor;
- (instancetype)initWithElementKind:(NSString *)elementKind size:(NSCollectionLayoutSize *)size contentInsets:(NSDirectionalEdgeInsets)contentInsets containerAnchor:(NSCollectionLayoutAnchor *)containerAnchor itemAnchor:(NSCollectionLayoutAnchor *)itemAnchor zIndex:(NSInteger)zIndex registrationViewClass:(Class)registrationViewClass isBackgroundDecoration:(BOOL)isBackgroundDecoration;
@end

NS_ASSUME_NONNULL_END
