//
//  EditorTrackCollectionViewLayoutAttributes.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayoutAttributes : NSCollectionViewLayoutAttributes
@property (copy, nonatomic) AVAsset * _Nullable (^ _Nullable assetResolver)(void);
@property (copy, nonatomic) CMTime (^ _Nullable timeResolver)(void);
@end

NS_ASSUME_NONNULL_END
