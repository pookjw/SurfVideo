//
//  EditorTrackCenterLineCollectionReusableView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/15/24.
//

#import "EditorTrackCenterLineCollectionReusableView.hpp"

@implementation EditorTrackCenterLineCollectionReusableView

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
}

@end
