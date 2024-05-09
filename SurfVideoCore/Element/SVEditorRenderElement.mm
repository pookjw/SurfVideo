//
//  SVEditorRenderElement.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <SurfVideoCore/SVEditorRenderElement.hpp>

@implementation SVEditorRenderElement

- (id)copyWithZone:(struct _NSZone *)zone {
    __kindof SVEditorRenderElement *copy = [[self class] new];
    return copy;
}

@end
