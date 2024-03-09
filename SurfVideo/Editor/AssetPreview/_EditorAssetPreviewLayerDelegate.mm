//
//  _EditorAssetPreviewLayerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "_EditorAssetPreviewLayerDelegate.hpp"
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface _EditorAssetPreviewLayerDelegate ()
@end

@implementation _EditorAssetPreviewLayerDelegate

+ (void *)imageContextKey {
    static void *imageContextKey = &imageContextKey;
    return imageContextKey;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (NSThread.isMainThread) return;
    
    if (id image = objc_getAssociatedObject(layer, _EditorAssetPreviewLayerDelegate.imageContextKey)) {
        auto imageRef = static_cast<CGImageRef>(image);
        
        CGRect bounds = layer.bounds;
        CGAffineTransform transform = CGAffineTransformMake(1.f, 0.f, 0.f, -1.f, 0.f, bounds.size.height);
        
        CGContextConcatCTM(ctx, transform);
        CGContextDrawImage(ctx, bounds, imageRef);
    }
}

@end
