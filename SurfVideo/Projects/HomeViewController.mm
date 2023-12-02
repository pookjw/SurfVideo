//
//  HomeViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "HomeViewController.hpp"
#import "ProjectsViewController.hpp"

__attribute__((objc_direct_members))
@interface HomeViewController ()
@property (retain, readonly, nonatomic) UITabBarController *childTabBarController;
@property (retain, readonly, nonatomic) ProjectsViewController *projectsViewController;
@end

@implementation HomeViewController

@synthesize childTabBarController = _childTabBarController;
@synthesize projectsViewController = _projectsViewController;

- (void)dealloc {
    [_childTabBarController release];
    [_projectsViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupChildTabBarController];
}

- (void)setupChildTabBarController __attribute__((objc_direct)) {
    UITabBarController *childTabBarController = self.childTabBarController;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.projectsViewController];
    navigationController.navigationBar.prefersLargeTitles = YES;
    [childTabBarController setViewControllers:@[navigationController] animated:NO];
    [navigationController release];
    [self addChildViewController:childTabBarController];
    
    UIView *contentView = childTabBarController.view;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [childTabBarController didMoveToParentViewController:self];
}

- (UITabBarController *)childTabBarController {
    if (_childTabBarController) return _childTabBarController;
    
    UITabBarController *ownTabBarController = [UITabBarController new];
    
    [_childTabBarController release];
    _childTabBarController = [ownTabBarController retain];
    
    return [ownTabBarController autorelease];
}

- (ProjectsViewController *)projectsViewController {
    if (_projectsViewController) return _projectsViewController;
    
    ProjectsViewController *projectsViewController = [ProjectsViewController new];
    
    [_projectsViewController release];
    _projectsViewController = [projectsViewController retain];
    
    return [projectsViewController autorelease];
}

@end
