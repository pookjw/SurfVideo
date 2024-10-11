//
//  _SVAudioWaveformViewLayerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <SurfVideoCore/_SVAudioWaveformViewLayerDelegate.hpp>

#if TARGET_OS_IPHONE

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include <vector>
#include <numeric>
#include <algorithm>

@implementation _SVAudioWaveformViewLayerDelegate

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
    
#warning 이 method는 여러 Thread에서 불릴 수 있으나 nonatomic으로 값을 쓰고 읽고 있어 data race 여지가 있다. lock이 필요하다.
    NSArray<NSNumber *> *samples = objc_getAssociatedObject(layer, _SVAudioWaveformViewLayerDelegate.samplesContextKey);
    if (samples == nil) return;
    
    UIColor *waveformColor;
    if (id _waveformColor = objc_getAssociatedObject(layer, _SVAudioWaveformViewLayerDelegate.waveformColorContextKey)) {
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
