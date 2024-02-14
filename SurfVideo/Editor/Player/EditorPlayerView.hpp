//
//  EditorPlayerView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/4/23.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EditorPlayerView;
@protocol EditorPlayerViewDelegate <NSObject>
- (void)editorPlayerView:(EditorPlayerView *)editorPlayerView didChangeCurrentTime:(CMTime)currentTime;
@end

__attribute__((objc_direct_members))
@interface EditorPlayerView : UIView
@property (weak) id<EditorPlayerViewDelegate> delegate;
@property (retain, nonatomic) AVPlayer * _Nullable player;
@end

NS_ASSUME_NONNULL_END
