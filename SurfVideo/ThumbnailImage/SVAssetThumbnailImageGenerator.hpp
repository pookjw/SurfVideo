//
//  SVAssetThumbnailImageGenerator.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SVAssetThumbnailImageGenerator : NSObject
- (NSProgress * _Nullable)requestThumbnailImagesFromAsset:(AVAsset *)asset assetID:(NSUUID *)assetID atTimes:(NSOrderedSet<NSValue *> *)times maximumSize:(CGSize)maximumSize requestHandler:(void (^)(CMTime requestedTime, CMTime actualTime, CGImageRef _Nullable image, NSError * _Nullable error, BOOL finished))requestHandler;
@end

NS_ASSUME_NONNULL_END
