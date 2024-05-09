//
//  ImageUtils.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/9/23.
//

#import <SurfVideoCore/ImageUtils.hpp>
#import <Metal/Metal.h>

__attribute__((objc_direct_members))
@interface ImageUtils ()
@property (class, retain, readonly, nonatomic) CIContext *ciContext;
@end

@implementation ImageUtils

+ (CIContext *)ciContext {
    static dispatch_once_t onceToken;
    static CIContext *ciContext;
    
    dispatch_once(&onceToken, ^{
        id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        ciContext = [[CIContext contextWithMTLDevice:mtlDevice] retain];
        [mtlDevice release];
    });
    
    return ciContext;
}

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

+ (NSData *)TIFFDataFromCIImage:(CIImage *)ciImage {
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    NSData *result = [ImageUtils.ciContext TIFFRepresentationOfImage:ciImage format:kCIFormatRGBA16 colorSpace:colorspace options:@{(id)kCGImageDestinationLossyCompressionQuality: @(1.f)}];
    CGColorSpaceRelease(colorspace);
    return result;
}

@end
