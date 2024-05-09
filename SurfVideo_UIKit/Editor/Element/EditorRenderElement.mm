//
//  EditorRenderElement.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "EditorRenderElement.hpp"

@implementation EditorRenderElement

- (id)copyWithZone:(struct _NSZone *)zone {
    __kindof EditorRenderElement *copy = [[self class] new];
    return copy;
}

@end
