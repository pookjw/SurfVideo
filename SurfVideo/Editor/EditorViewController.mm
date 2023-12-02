//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorViewModel.hpp"
#import <memory>

__attribute__((objc_direct_members))
@interface EditorViewController ()
@property (assign, nonatomic) std::shared_ptr<EditorViewModel> viewModel;
@end

@implementation EditorViewController

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = std::make_shared<EditorViewModel>(userActivities);
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _viewModel.get()->initialize(_viewModel, ^(NSError * _Nullable error) {
        assert(!error);
    });
}

- (void)commonInit_EditorViewController __attribute__((objc_direct)) {
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Editor";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}

@end
