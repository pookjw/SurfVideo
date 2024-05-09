//
//  AVAsset+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (Private)
- (NSURL * _Nullable)_absoluteURL;
@end

NS_ASSUME_NONNULL_END
