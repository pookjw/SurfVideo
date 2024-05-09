//
//  _AudioWaveformViewLayerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <SurfVideoCore/_AudioWaveformViewLayerDelegate.hpp>

#if TARGET_OS_IPHONE

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include <vector>
#include <numeric>
#include <algorithm>

@implementation _AudioWaveformViewLayerDelegate

+ (void *)waveformColorContextKey {
    static void *waveformColorContextKey = &waveformColorContextKey;
    return waveformColorContextKey;
}

+ (void *)samplesContextKey {
    static void *samplesContextKey = &samplesContextKey;
    return samplesContextKey;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (NSThread.isMainThread) return;
    
    NSArray<NSNumber *> *samples = objc_getAssociatedObject(layer, _AudioWaveformViewLayerDelegate.samplesContextKey);
    if (samples == nil) return;
    
    UIColor *waveformColor;
    if (id _waveformColor = objc_getAssociatedObject(layer, _AudioWaveformViewLayerDelegate.waveformColorContextKey)) {
        waveformColor = _waveformColor;
    } else {
        waveformColor = UIColor.tintColor;
    }
    
    NSUInteger count = samples.count;
    std::vector<NSInteger> sampleIndices(count);
    std::iota(sampleIndices.begin(), sampleIndices.end(), 0);
    
    CGRect bounds = layer.bounds;
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat sampleWidth = CGRectGetWidth(bounds) / count;
    
    CGContextSetFillColorWithColor(ctx, waveformColor.CGColor);
    
    for (NSInteger index : sampleIndices) {
        float sample = samples[index].floatValue;
        
        CGFloat sampleHeight = height * sample;
        CGRect rect = CGRectMake(std::fmax(0.f, sampleWidth * (index - 1)),
                                 (height - sampleHeight) * 0.5f,
                                 sampleWidth, 
                                 sampleHeight);
        
        CGContextAddRect(ctx, rect);
    }
    
    CGContextFillPath(ctx);
}

@end

#endif
