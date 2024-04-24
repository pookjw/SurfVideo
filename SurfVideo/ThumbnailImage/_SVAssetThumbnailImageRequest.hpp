//
//  _SVAssetThumbnailImageRequest.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface _SVAssetThumbnailImageRequest : NSObject
@property (copy, readonly, nonatomic) NSUUID *assetID;
@property (retain, readonly, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (copy, readonly, nonatomic) NSOrderedSet<NSValue *> *times;
@property (assign, readonly, nonatomic) CGSize maximumSize;
@property (retain, readonly, nonatomic) NSMutableDictionary<NSValue *, NSMutableArray< void (^)(CMTime requestedTime, CMTime actualTime, CGImageRef _Nullable image, NSError * _Nullable error)> *> *completionBlocksByTime;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAssetID:(NSUUID *)assetID assetImageGenerator:(AVAssetImageGenerator *)assetImageGenerator times:(NSOrderedSet<NSValue *> *)times maximumSize:(CGSize)maximumSize  NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
