//
//  EditorRenderer.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/20/24.
//

#import "EditorRenderer.hpp"
#import "ImageUtils.hpp"
#import <Metal/Metal.h>

@implementation EditorRenderer

+ (void)videoCompositionWithComposition:(AVComposition *)composition completionHandler:(void (^)(AVVideoComposition * _Nullable, NSError * _Nullable))completionHandler {
    CGSize naturalSize = composition.naturalSize;
    
    id <MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
    CIContext *ciContext = [CIContext contextWithMTLDevice:mtlDevice];
    [mtlDevice release];
    
    [AVVideoComposition videoCompositionWithAsset:composition 
                     applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        CIImage *transformedImage = [EditorRenderer transformedImageWithSourceImage:request.sourceImage naturalSize:naturalSize];
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     naturalSize.width,
                                                     naturalSize.height,
                                                     16,
                                                     20480,
                                                     colorSpace,
                                                     4353);
        CGColorSpaceRelease(colorSpace);
        
//        CIContext *ciContext = [CIContext contextWithCGContext:context options:nil];
        CGImageRef finalCGImage = [ciContext createCGImage:transformedImage fromRect:CGRectMake(0.f, 0.f, naturalSize.width, naturalSize.height)];
        CGContextDrawImage(context, 
                           CGRectMake(0.f, 0.f, naturalSize.width, naturalSize.height),
                           finalCGImage);
        CGImageRelease(finalCGImage);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.fontSize = 60.f;
        textLayer.frame = CGRectMake(0.f,
                                     CGBitmapContextGetHeight(context) * 0.8f - 60.f,
                                     CGBitmapContextGetWidth(context), 
                                     60.f);
        
        textLayer.string = @"Test";
        textLayer.backgroundColor = CGColorCreateSRGB(0.f, 0.f, 0.f, 0.3f);
        textLayer.foregroundColor = CGColorCreateSRGB(1.f, 1.f, 1.f, 1.f);
        
        CALayer *parentLayer = [CALayer new];
        parentLayer.bounds = CGRectMake(0.f,
                                        0.f,
                                        CGBitmapContextGetWidth(context),
                                        CGBitmapContextGetHeight(context));
        
        [parentLayer addSublayer:textLayer];
        [parentLayer release];
        
        CGAffineTransform transform = CGAffineTransformMake(1.f, 0.f, 0.f, -1.f, 0.f, naturalSize.height);
        CGContextConcatCTM(context, transform);
        [parentLayer renderInContext:context];
        [parentLayer release];
        CGContextConcatCTM(context, CGAffineTransformInvert(transform));
        
        CGImageRef contextImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        CIImage *finalImage2 = [CIImage imageWithCGImage:contextImage];
        CGImageRelease(contextImage);
        
        // context == nil -> -[AVCoreImageFilterCustomVideoCompositor defaultCIContext]
        [request finishWithImage:finalImage2 context:ciContext];
        [pool release];
    }
                                completionHandler:completionHandler];
}

+ (CIImage *)transformedImageWithSourceImage:(CIImage *)sourceImage naturalSize:(CGSize)naturalSize __attribute__((objc_direct)) {
    CIImage *image2 = [ImageUtils aspectFitImageWithImage:sourceImage targetSize:naturalSize].imageByClampingToExtent;
    CIColor *color = [[CIColor alloc] initWithRed:1.f green:1.f blue:1.f alpha:1.f];
    CIImage *finalImage = [image2 imageByCompositingOverImage:[CIImage imageWithColor:color]];
    [color release];
    
    return finalImage;
} 

@end
