//
//  _AudioWaveformViewLayerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import "_AudioWaveformViewLayerDelegate.hpp"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include <vector>
#include <unordered_map>
#include <utility>
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
    std::unordered_map<NSUInteger, std::pair<float, float>> sampleRangesPerCompoent {};
    
    for (NSInteger index : sampleIndices) {
        CGFloat x = std::fmax(0.f, sampleWidth * (index - 1));
        NSUInteger component = x / 50.f;
        
        std::pair<float, float> sampleRanges;
        if (sampleRangesPerCompoent.find(component) != sampleRangesPerCompoent.end()) {
            sampleRanges = sampleRangesPerCompoent.at(component);
        } else {
            sampleRanges = {FLT_MAX, -FLT_MAX};
        }
        
        float sample = samples[index].floatValue;
        
        sampleRanges = {
            std::fmin(sampleRanges.first, sample),
            std::fmax(sampleRanges.second, sample),
        };
        
        sampleRangesPerCompoent.insert_or_assign(component, sampleRanges);
    }
    
    CGContextSetFillColorWithColor(ctx, waveformColor.CGColor);
    
    for (NSInteger index : sampleIndices) {
        CGFloat x = std::fmax(0.f, sampleWidth * (index - 1));
        NSUInteger component = x / 50.f;
        std::pair<float, float> sampleRanges = sampleRangesPerCompoent.at(component);
        float minSample = sampleRanges.first;
        float maxSample = sampleRanges.second;
        
        float sample = samples[index].floatValue;
        float normalizedSample = (sample - minSample) / (maxSample - minSample);
        
        CGFloat sampleHeight = height * normalizedSample;
        CGRect rect = CGRectMake(std::fmax(0.f, sampleWidth * (index - 1)),
                                 height * (1.f - normalizedSample) * 0.5f,
                                 sampleWidth * index, 
                                 sampleHeight);
        
        CGContextAddRect(ctx, rect);
    }
    
    CGContextFillPath(ctx);
}

@end
