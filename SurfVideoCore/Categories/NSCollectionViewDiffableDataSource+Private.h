//
//  NSCollectionViewDiffableDataSource+Private.h
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCollectionViewDiffableDataSource <SectionIdentifierType,ItemIdentifierType> (Private)
- (void)applySnapshot:(NSDiffableDataSourceSnapshot<SectionIdentifierType,ItemIdentifierType>*)snapshot animatingDifferences:(BOOL)animatingDifferences completion:(void(^ _Nullable)(void))completion NS_SWIFT_DISABLE_ASYNC __attribute__((swift_attr("nonisolated")));
@end

NS_ASSUME_NONNULL_END

#endif
