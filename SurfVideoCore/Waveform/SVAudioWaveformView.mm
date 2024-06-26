//
//  SVAudioWaveformView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <SurfVideoCore/SVAudioWaveformView.hpp>

#if TARGET_OS_IPHONE

#import <SurfVideoCore/SVAudioSamplesManager.hpp>
#import <SurfVideoCore/SVRunLoop.hpp>
#import <SurfVideoCore/_SVAudioWaveformViewLayerDelegate.hpp>
#import <objc/runtime.h>

OBJC_EXPORT void objc_setProperty_atomic_copy(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);
OBJC_EXPORT id _Nullable objc_getProperty(id _Nullable self, SEL _Nonnull _cmd, ptrdiff_t offset, BOOL atomic);

__attribute__((objc_direct_members))
@interface SVAudioWaveformView ()
@property (retain, readonly, nonatomic) CALayer *sublayer;
@property (retain, readonly, nonatomic) _SVAudioWaveformViewLayerDelegate *delegate;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@property (assign, nonatomic) CGRect oldRect;
@end

@implementation SVAudioWaveformView

@synthesize avAsset = _avAsset;
@synthesize waveformColor = _waveformColor;
@synthesize sublayer = _sublayer;
@synthesize delegate = _delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_AudioWaveformView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_AudioWaveformView];
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [_waveformColor release];
    [_sublayer release];
    [_delegate release];
    [_progress cancel];
    [_progress release];
    [super dealloc];
}

- (void)commonInit_AudioWaveformView __attribute__((objc_direct)) {
    [self.layer addSublayer:self.sublayer];
    
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        [self.sublayer setNeedsDisplay];
    }];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (!CGRectEqualToRect(self.oldRect, frame)) {
        self.sublayer.frame = self.layer.bounds;
        [SVRunLoop.globalRenderRunLoop runBlock:^{
            [self.sublayer setNeedsDisplay];
        }];
        
        self.oldRect = frame;
    }
}

- (AVAsset *)avAsset {
    return objc_getProperty(self, _cmd, (ptrdiff_t)((uintptr_t)(&_avAsset) - (uintptr_t)self), YES);
}

- (void)setAVAsset:(AVAsset *)avAsset {
    if ([self.avAsset isEqual:avAsset]) return;
    
    [self.progress cancel];
    
    objc_setProperty_atomic_copy(self, _cmd, avAsset, (ptrdiff_t)((uintptr_t)(&_avAsset) - (uintptr_t)self));
    
    CALayer *sublayer = self.sublayer;
    __weak auto weakSelf = self;
    
    self.progress = [SVAudioSamplesManager.sharedInstance audioSampleFromAsset:avAsset
                                                             completionHandler:^(SVAudioSample * _Nullable audioSample, NSError * _Nullable error) {
        assert(!error);
        
        [audioSample.managedObjectContext performBlock:^{
            NSArray<NSNumber *> *samples = audioSample.samples;
            
            [SVRunLoop.globalRenderRunLoop runBlock:^{
                if (![weakSelf.avAsset isEqual:avAsset]) return;
                
                objc_setAssociatedObject(sublayer, 
                                         _SVAudioWaveformViewLayerDelegate.samplesContextKey,
                                         samples,
                                         OBJC_ASSOCIATION_COPY_NONATOMIC);
                objc_setAssociatedObject(sublayer, 
                                         _SVAudioWaveformViewLayerDelegate.waveformColorContextKey,
                                         weakSelf.waveformColor,
                                         OBJC_ASSOCIATION_COPY_NONATOMIC);
                
                [sublayer setNeedsDisplay];
            }];
        }];
    }];
}

- (UIColor *)waveformColor {
    return objc_getProperty(self, _cmd, (ptrdiff_t)((uintptr_t)(&_waveformColor) - (uintptr_t)self), YES);
}

- (void)setWaveformColor:(UIColor *)waveformColor {
    [_waveformColor release];
    objc_setProperty_atomic_copy(self, _cmd, waveformColor, (ptrdiff_t)((uintptr_t)(&_waveformColor) - (uintptr_t)self));
    
    CALayer *sublayer = self.sublayer;
    __weak auto weakSelf = self;
    
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        if (![weakSelf.waveformColor isEqual:waveformColor]) return;
        
        objc_setAssociatedObject(sublayer, 
                                 _SVAudioWaveformViewLayerDelegate.waveformColorContextKey,
                                 waveformColor,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        if (objc_getAssociatedObject(sublayer, _SVAudioWaveformViewLayerDelegate.samplesContextKey) != NULL) {
            [sublayer setNeedsDisplay];
        }
    }];
}

- (CALayer *)sublayer {
    if (auto sublayer = _sublayer) return sublayer;
    
    CALayer *sublayer = [CALayer new];
    sublayer.delegate = self.delegate;
    
    _sublayer = [sublayer retain];
    return [sublayer autorelease];
}

- (_SVAudioWaveformViewLayerDelegate *)delegate {
    if (auto delegate = _delegate) return delegate;
    
    _SVAudioWaveformViewLayerDelegate *delegate = [_SVAudioWaveformViewLayerDelegate new];
    
    _delegate = [delegate retain];
    return [delegate autorelease];
}

@end

#endif
