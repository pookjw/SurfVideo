//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import "EditorTrackViewModel.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackViewController ()
@property (assign, nonatomic) std::shared_ptr<EditorTrackViewModel> viewModel;
@end

@implementation EditorTrackViewController
@synthesize composition = _composition;

- (instancetype)initWithEditorViewModel:(std::shared_ptr<EditorViewModel>)editorViewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = std::make_shared<EditorTrackViewModel>(editorViewModel);
    }
    
    return self;
}

- (void)dealloc {
    [_composition release];
    [super dealloc];
}

- (AVComposition *)composition {
    return 0;
}

- (void)setComposition:(AVComposition *)composition {
    NSLog(@"%@", composition);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemOrangeColor;
}

@end
