//
//  NSCollectionViewDiffableDataSource+Category.mm
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import <SurfVideoCore/NSCollectionViewDiffableDataSource+Category.hpp>

#if TARGET_OS_OSX

#import <objc/message.h>
#import <objc/runtime.h>

@implementation NSCollectionViewDiffableDataSource (Category)

- (id)sv_sectionIdentifierForIndex:(NSInteger)index {
    return ((id (*)(id, SEL, NSInteger))objc_msgSend)([self sv_impl], sel_registerName("sectionIdentifierForIndex:"), index);
}

- (NSInteger)sv_indexForSectionIdentifier:(id)identifier {
    return ((NSInteger (*)(id, SEL, id))objc_msgSend)([self sv_impl], sel_registerName("indexForSectionIdentifier:"), identifier);
}

- (id /* __NSDiffableDataSource * */)sv_impl __attribute__((objc_direct)) {
    return ((id (*)(id, SEL))objc_msgSend)(self, sel_registerName("impl"));
}

@end

#endif
