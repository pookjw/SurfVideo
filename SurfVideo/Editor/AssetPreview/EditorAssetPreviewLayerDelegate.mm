//
//  EditorAssetPreviewLayerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "EditorAssetPreviewLayerDelegate.hpp"
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface EditorAssetPreviewLayerDelegate ()
@end

@implementation EditorAssetPreviewLayerDelegate

+ (void *)imageContextKey {
    static void *imageContextKey = &imageContextKey;
    return imageContextKey;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (id image = objc_getAssociatedObject(layer, EditorAssetPreviewLayerDelegate.imageContextKey)) {
        auto imageRef = static_cast<CGImageRef>(image);
        
        CGContextDrawImage(ctx, layer.bounds, imageRef);
    }
}

@end
