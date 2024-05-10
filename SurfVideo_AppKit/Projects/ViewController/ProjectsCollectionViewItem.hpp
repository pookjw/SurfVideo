//
//  ProjectsCollectionViewItem.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsCollectionViewItem : NSCollectionViewItem
@property (class, readonly, nonatomic) NSUserInterfaceItemIdentifier reuseIdentifier;
@end

NS_ASSUME_NONNULL_END
