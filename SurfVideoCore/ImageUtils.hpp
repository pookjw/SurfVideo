//
//  ImageUtils.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/9/23.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageUtils : NSObject
+ (CIImage *)aspectFitImageWithImage:(CIImage *)originalImage targetSize:(CGSize)targetSize;
+ (NSData *)TIFFDataFromCIImage:(CIImage *)ciImage;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
