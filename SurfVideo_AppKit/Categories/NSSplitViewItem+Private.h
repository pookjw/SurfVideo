//
//  NSSplitViewItem+Private.h
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSplitViewItem (Private)
- (void)setMinimumSize:(CGFloat)minimumSize;
- (void)setMaximumSize:(CGFloat)maximumSize;
- (CGFloat)maximumSize;
- (CGFloat)minimumSize;
@end

NS_ASSUME_NONNULL_END
