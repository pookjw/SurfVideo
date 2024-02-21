//
//  EditorRenderCaption.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "EditorRenderElement.hpp"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorRenderCaption : EditorRenderElement
@property (copy, readonly, nonatomic) NSAttributedString *attributedString;
@property (assign, readonly, nonatomic) CMTime startTime;
@property (assign, readonly, nonatomic) CMTime endTime;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
