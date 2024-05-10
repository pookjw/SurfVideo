//
//  PopoverTransition.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface PopoverTransition : NSObject <NSViewControllerPresentationAnimator>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRelativeToolbarItem:(NSToolbarItem *)toolbarItem behavior:(NSPopoverBehavior)behavior;
@end

NS_ASSUME_NONNULL_END
