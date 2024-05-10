//
//  EditorWindow.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorWindow.hpp"

__attribute__((objc_direct_members))
@interface EditorWindow ()
@property (retain, readonly, nonatomic) SVVideoProject *videoProject;
@end

@implementation EditorWindow

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    self = [self initWithContentRect:NSMakeRect(0., 0., 600., 400.)
                           styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView
                             backing:NSBackingStoreBuffered
                               defer:YES];
    
    if (self) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_videoProject release];
    [super dealloc];
}

@end
