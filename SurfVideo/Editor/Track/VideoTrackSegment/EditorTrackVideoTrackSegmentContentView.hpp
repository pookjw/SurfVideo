//
//  EditorTrackVideoTrackSegmentContentView.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import <UIKit/UIKit.h>
#import "EditorTrackVideoTrackSegmentContentConfiguration.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackVideoTrackSegmentContentView : UIView <UIContentView>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithContentConfiguration:(EditorTrackVideoTrackSegmentContentConfiguration *)contentConfiguration NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
