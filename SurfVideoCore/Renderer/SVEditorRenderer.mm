//
//  SVEditorRenderer.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/20/24.
//

#import <SurfVideoCore/SVEditorRenderer.hpp>
#import <SurfVideoCore/SVImageUtils.hpp>
#import <SurfVideoCore/SVEditorRenderCaption.hpp>
#import <Metal/Metal.h>

__attribute__((objc_direct_members))
@interface SVEditorRenderer ()
@property (class, readonly, nonatomic) CIContext *sharedCIContext;
@end

@implementation SVEditorRenderer

+ (CIContext *)sharedCIContext {
    static dispatch_once_t onceToken;
    static CIContext *instance;
    
    dispatch_once(&onceToken, ^{
        id <MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        instance = [[CIContext contextWithMTLDevice:mtlDevice] retain];
        [mtlDevice release];
    });
    
    return instance;
}

+ (void)videoCompositionWithComposition:(AVComposition *)composition elements:(NSArray<__kindof SVEditorRenderElement *> *)elements completionHandler:(void (^)(AVVideoComposition * _Nullable, NSError * _Nullable))completionHandler {
    CIContext *ciContext = SVEditorRenderer.sharedCIContext;
    
    [AVVideoComposition videoCompositionWithAsset:composition 
                     applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     request.renderSize.width,
                                                     request.renderSize.height,
                                                     16,
                                                     30720,
                                                     colorSpace,
                                                     4353);
        CGColorSpaceRelease(colorSpace);
        
        [SVEditorRenderer renderTransformedImageWithRequest:request inCGContext:context ciContext:ciContext];
        [SVEditorRenderer renderElements:elements withRequest:request inCGContext:context];
        
        CGImageRef contextImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        CIImage *finalImage = [CIImage imageWithCGImage:contextImage];
        CGImageRelease(contextImage);
        
        // context == nil -> -[AVCoreImageFilterCustomVideoCompositor defaultCIContext]
        [request finishWithImage:finalImage context:ciContext];
    }
                                completionHandler:completionHandler];
}

+ (void)renderTransformedImageWithRequest:(AVAsynchronousCIImageFilteringRequest *)request inCGContext:(CGContextRef)cgContext ciContext:(CIContext *)ciContext __attribute__((objc_direct)) {
    CGSize targetSize = request.renderSize;
    
    CIImage *transformedImage = [SVEditorRenderer transformedImageWithSourceImage:request.sourceImage
                                                                     targetSize:targetSize];
    
    CGImageRef finalCGImage = [ciContext createCGImage:transformedImage fromRect:CGRectMake(0.f, 0.f, targetSize.width, targetSize.height)];
    
    CGContextDrawImage(cgContext, 
                       CGRectMake(0.f, 0.f, targetSize.width, targetSize.height),
                       finalCGImage);
    
    CGImageRelease(finalCGImage);
}

+ (void)renderElements:(NSArray<__kindof SVEditorRenderElement *> *)elements withRequest:(AVAsynchronousCIImageFilteringRequest *)request inCGContext:(CGContextRef)cgContext __attribute__((objc_direct)) {
    CGSize targetSize = CGSizeMake(CGBitmapContextGetWidth(cgContext),
                                   CGBitmapContextGetHeight(cgContext));
    
    for (__kindof SVEditorRenderElement *element in elements) {
        if ([element isKindOfClass:SVEditorRenderCaption.class]) {
            auto renderCaption = static_cast<SVEditorRenderCaption *>(element);
            
            if (CMTimeCompare(renderCaption.startTime, request.compositionTime) < 1 && CMTimeCompare(request.compositionTime, renderCaption.endTime) < 1) {
                CATextLayer *textLayer = [CATextLayer new];
                textLayer.fontSize = 60.f;
                textLayer.frame = CGRectMake(0.f,
                                             CGBitmapContextGetHeight(cgContext) * 0.8f - textLayer.fontSize,
                                             CGBitmapContextGetWidth(cgContext), 
                                             textLayer.fontSize);
                
                textLayer.string = renderCaption.attributedString.string;
                
                CGColorRef backgroundColor = CGColorCreateSRGB(0.f, 0.f, 0.f, 0.3f);
                textLayer.backgroundColor = backgroundColor;
                CGColorRelease(backgroundColor);
                
                CGColorRef foregroundColor = CGColorCreateSRGB(1.f, 1.f, 1.f, 1.f);
                textLayer.foregroundColor = foregroundColor;
                CGColorRelease(foregroundColor);
                
                CALayer *parentLayer = [CALayer new];
                parentLayer.bounds = CGRectMake(0.f,
                                                0.f,
                                                targetSize.width,
                                                targetSize.height);
                
                [parentLayer addSublayer:textLayer];
                [textLayer release];
                
                CGAffineTransform transform = CGAffineTransformMake(1.f, 0.f, 0.f, -1.f, 0.f, targetSize.height);
                CGContextConcatCTM(cgContext, transform);
                [parentLayer renderInContext:cgContext];
                [parentLayer release];
                CGContextConcatCTM(cgContext, CGAffineTransformInvert(transform));
            }
        }
    }
}

+ (CIImage *)transformedImageWithSourceImage:(CIImage *)sourceImage targetSize:(CGSize)targetSize __attribute__((objc_direct)) {
    CIImage *image2 = [SVImageUtils aspectFitImageWithImage:sourceImage targetSize:targetSize].imageByClampingToExtent;
    CIColor *color = [[CIColor alloc] initWithRed:0.f green:0.f blue:0.f alpha:0.f];
    CIImage *finalImage = [image2 imageByCompositingOverImage:[CIImage imageWithColor:color]];
    [color release];
    
    return finalImage;
}

@end
