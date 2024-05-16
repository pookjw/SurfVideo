//
//  SVCollectionView.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/17/24.
//

#import "SVCollectionView.hpp"
#import <objc/message.h>

OBJC_EXPORT id objc_msgSendSuper2(void);

@implementation SVCollectionView

- (BOOL)_autoConfigureScrollers {
    return NO;
}

- (void)_resizeToFitContentAndClipView {
    struct objc_super superInfo = { self, [self class] };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper2)(&superInfo, _cmd);
    
    [self setFrameSize:self.collectionViewLayout.collectionViewContentSize];
}

@end
