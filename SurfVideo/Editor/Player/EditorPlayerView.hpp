//
//  EditorPlayerView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/4/23.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorPlayerView : UIView
@property (retain, nonatomic) AVPlayer * _Nullable player;
@end

NS_ASSUME_NONNULL_END
