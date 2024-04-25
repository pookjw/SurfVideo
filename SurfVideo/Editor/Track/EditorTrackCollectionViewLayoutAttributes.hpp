//
//  EditorTrackCollectionViewLayoutAttributes.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/26/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes
@property (copy, nonatomic) AVAsset * _Nullable (^ _Nullable assetResolver)(void);
@property (copy, nonatomic) CMTime (^ _Nullable timeResolver)(void);
@end

NS_ASSUME_NONNULL_END
