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

- (EditorService *)editorService {
    return self.editorViewController.editorService;
}

- (void)editorViewController_viewDidLoad {
    
}

@end
