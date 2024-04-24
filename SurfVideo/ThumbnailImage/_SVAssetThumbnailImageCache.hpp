//
//  _SVAssetThumbnailImageCache.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface _SVAssetThumbnailImageCache : NSObject
@property (copy, readonly, nonatomic) NSUUID *assetID;
@property (assign, readonly, nonatomic) CMTime requestedTime;
@property (assign, readonly, nonatomic) CMTime actualTime;
@property (assign, readonly, nonatomic) CGImageRef image;
@property (assign, readonly, nonatomic) CGSize maximumSize;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAssetID:(NSUUID *)assetID requestedTime:(CMTime)requestedTime actualTime:(CMTime)actualTime image:(CGImageRef)image maximumSize:(CGSize)maximumSize NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
