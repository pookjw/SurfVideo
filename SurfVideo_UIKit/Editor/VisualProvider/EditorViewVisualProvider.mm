//
//  EditorViewVisualProvider.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import "EditorViewVisualProvider.hpp"
#import "EditorViewController+Private.hpp"

@implementation EditorViewVisualProvider

- (instancetype)initWithEditorViewController:(EditorViewController *)editorViewController {
    if (self = [super init]) {
        _editorViewController = editorViewController;
    }
    
    return self;
}

- (EditorPlayerViewController *)playerViewController {
    return self.editorViewController.playerViewController;
}

- (EditorTrackViewController *)trackViewController {
    return self.editorViewController.trackViewController;
}

- (SVEditorService *)editorService {
    return self.editorViewController.editorService;
}

- (void)editorViewController_viewDidLoad {
    
}

- (void)playEffectsWithRenderEffects:(NSArray<SVEditorRenderEffect *> *)renderEffects {
    
}

- (void)clearEffects {
    
}

@end
