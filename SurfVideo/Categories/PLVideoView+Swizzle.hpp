//
//  PLVideoView+Swizzle.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const SV_PLVideoViewDidMoviePlayerReadyToPlayNotification;

@interface UIResponder (PLVideoView_Swizzle)
@end

NS_ASSUME_NONNULL_END
