//
//  ProjectsCollectionViewLayout.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "ProjectsCollectionViewLayout.hpp"
#include <numeric>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation ProjectsCollectionViewLayout
#pragma clang diagnostic pop

- (instancetype)init {
    NSCollectionViewCompositionalLayoutConfiguration *configuration = [NSCollectionViewCompositionalLayoutConfiguration new];
    configuration.scrollDirection = NSCollectionViewScrollDirectionVertical;
    
    self = [super initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
       NSUInteger quotient = std::floorf(layoutEnvironment.container.contentSize.width / 200.f);
       NSUInteger count = MAX(quotient, 2);
       
       NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f / count]
                                                                         heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
       
       NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
       item.contentInsets = NSDirectionalEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
       
       NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f]
                                                                          heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f / count]];
       
       NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitem:item count:count];
       
       NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
       section.contentInsets = NSDirectionalEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
       
       return section;
   } 
                           configuration:configuration];
   
   [configuration release];
   
   return self;
}

@end
