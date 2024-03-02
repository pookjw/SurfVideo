//
//  CornerBlurView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/3/24.
//

#import "CornerBlurView.hpp"
#import <objc/message.h>
#import <objc/runtime.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation CornerBlurView

+ (Class)layerClass {
    return objc_lookUpClass("CABackdropLayer");
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_CornerBlurView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_CornerBlurView];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    for (CALayer *sublayer in self.layer.sublayers) {
        sublayer.frame = frame;
    }
}

- (void)commonInit_CornerBlurView __attribute__((objc_direct)) {
    __kindof CALayer *backdropLayer = self.layer;
    
    //
    
    CALayer *blurLayer = [objc_lookUpClass("CABackdropLayer") new];
    NSURL *imageURL = [NSBundle.mainBundle URLForResource:@"gradient" withExtension:UTTypePNG.preferredFilenameExtension];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    UIImage *image = [UIImage imageWithData:data];
    CGImageRef cgImageRef = image.CGImage;
    id caFilter = ((id (*)(Class, SEL, id))objc_msgSend)(objc_lookUpClass("CAFilter"), sel_registerName("filterWithName:"), @"variableBlur");
    [caFilter setValue:(id)cgImageRef forKey:@"inputMaskImage"];
    [caFilter setValue:@5.f forKey:@"inputRadius"];
    [caFilter setValue:@YES forKey:@"inputNormalizeEdges"];
    
    blurLayer.filters = @[caFilter];
    //
    
    [backdropLayer addSublayer:blurLayer];
    [blurLayer release];
    
    reinterpret_cast<void (*)(id, SEL, CGFloat)>(objc_msgSend)(backdropLayer, sel_registerName("setZoom:"), 0.05f);
}

@end
