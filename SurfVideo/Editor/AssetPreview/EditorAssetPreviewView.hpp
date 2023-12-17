//
//  EditorAssetPreviewView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView : UIView
- (void)updateWithAVAsset:(AVAsset *)avAsset timeRange:(CMTimeRange)timeRange;
@end

NS_ASSUME_NONNULL_END
