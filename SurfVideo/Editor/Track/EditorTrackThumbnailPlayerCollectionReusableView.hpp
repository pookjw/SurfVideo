//
//  EditorTrackThumbnailPlayerCollectionReusableView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/25/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackThumbnailPlayerCollectionReusableView : UICollectionReusableView
@property (class, readonly, nonatomic) NSString *elementKind;
- (void)updateWithAVAsset:(AVAsset *)avAsset time:(CMTime)time;
@end

NS_ASSUME_NONNULL_END
