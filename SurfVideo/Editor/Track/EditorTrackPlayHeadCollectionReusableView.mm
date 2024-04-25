//
//  EditorTrackPlayHeadCollectionReusableView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/15/24.
//

#import "EditorTrackPlayHeadCollectionReusableView.hpp"
//#import <objc/message.h>

@implementation EditorTrackPlayHeadCollectionReusableView

+ (NSString *)elementKind {
    return @"EditorTrackPlayHeadCollectionReusableView";
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_EditorTrackCenterLineCollectionReusableView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorTrackCenterLineCollectionReusableView];
    }
    
    return self;
}

- (void)commonInit_EditorTrackCenterLineCollectionReusableView __attribute__((objc_direct)) {
    self.backgroundColor = UIColor.tintColor;
//    reinterpret_cast<void (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(self, NSSelectorFromString(@"_requestSeparatedState:withReason:"), 1, @"SwiftUI.Transform3D");
//    self.layer.zPosition = 30.f;
}

@end
