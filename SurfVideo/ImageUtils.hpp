//
//  ImageUtils.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/9/23.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ImageUtils : NSObject
+ (CIImage *)aspectFitImageWithImage:(CIImage *)originalImage targetSize:(CGSize)targetSize;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
