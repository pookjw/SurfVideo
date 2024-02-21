//
//  EditorRenderCaption.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "EditorRenderCaption.hpp"

@implementation EditorRenderCaption

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime {
    if (self = [super init]) {
        _attributedString = [attributedString copy];
        _startTime = startTime;
        _endTime = endTime;
    }
    
    return self;
}

- (void)dealloc {
    [_attributedString release];
    [super dealloc];
}

@end
