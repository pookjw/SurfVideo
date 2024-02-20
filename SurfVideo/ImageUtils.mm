//
//  ImageUtils.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/9/23.
//

#import "ImageUtils.hpp"

@implementation ImageUtils

+ (CIImage *)aspectFitImageWithImage:(CIImage *)originalImage targetSize:(CGSize)targetSize {
    CGFloat aspect = originalImage.extent.size.width / originalImage.extent.size.height;
    CGFloat targetAspect = targetSize.width / targetSize.height;

    CGFloat scale = 1.0;
    if (aspect > targetAspect) {
        scale = targetSize.width / originalImage.extent.size.width;
    } else {
        scale = targetSize.height / originalImage.extent.size.height;
    }

    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    CIImage *scaledImage = [originalImage imageByApplyingTransform:scaleTransform];

    CGFloat xOffset = (targetSize.width - scaledImage.extent.size.width) / 2.0;
    CGFloat yOffset = (targetSize.height - scaledImage.extent.size.height) / 2.0;
    CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(xOffset, yOffset);
    CIImage *centeredImage = [scaledImage imageByApplyingTransform:translationTransform];
    
    return centeredImage;
}

@end
