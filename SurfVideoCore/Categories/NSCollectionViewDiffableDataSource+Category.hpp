//
//  NSCollectionViewDiffableDataSource+Category.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSCollectionViewDiffableDataSource <SectionIdentifierType,ItemIdentifierType> (Category)
- (nullable SectionIdentifierType)sv_sectionIdentifierForIndex:(NSInteger)index;
- (NSInteger)sv_indexForSectionIdentifier:(SectionIdentifierType)identifier;
@end

NS_ASSUME_NONNULL_END

#endif
