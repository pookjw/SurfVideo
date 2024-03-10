//
//  HomeViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "HomeViewController.hpp"
#import "ProjectsViewController.hpp"
#import "SettingsViewController.hpp"

__attribute__((objc_direct_members))
@interface HomeViewController ()
@property (retain, readonly, nonatomic) UITabBarController *childTabBarController;
@property (retain, readonly, nonatomic) ProjectsViewController *projectsViewController;
@property (retain, readonly, nonatomic) SettingsViewController *settingsViewController;
@end

@implementation HomeViewController

@synthesize childTabBarController = _childTabBarController;
@synthesize projectsViewController = _projectsViewController;
@synthesize settingsViewController = _settingsViewController;

- (void)dealloc {
    [_childTabBarController release];
    [_projectsViewController release];
    [_settingsViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupChildTabBarController];
}

- (void)setupChildTabBarController __attribute__((objc_direct)) {
    UITabBarController *childTabBarController = self.childTabBarController;
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
    if (auto childTabBarController = _childTabBarController) return childTabBarController;
    
    UITabBarController *childTabBarController = [UITabBarController new];
    
    UINavigationController *projectsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.projectsViewController];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
    
    projectsNavigationController.navigationBar.prefersLargeTitles = YES;
    settingsNavigationController.navigationBar.prefersLargeTitles = YES;
    
    [childTabBarController setViewControllers:@[projectsNavigationController, settingsNavigationController] animated:NO];
    
    [projectsNavigationController release];
    [settingsNavigationController release];
    
    _childTabBarController = [childTabBarController retain];
    return [childTabBarController autorelease];
}

- (ProjectsViewController *)projectsViewController {
    if (auto projectsViewController = _projectsViewController) return projectsViewController;
    
    ProjectsViewController *projectsViewController = [ProjectsViewController new];
    
    _projectsViewController = [projectsViewController retain];
    return [projectsViewController autorelease];
}

- (SettingsViewController *)settingsViewController {
    if (auto settingsViewController = _settingsViewController) return settingsViewController;
    
    SettingsViewController *settingsViewController = [SettingsViewController new];
    
    _settingsViewController = [settingsViewController retain];
    return [settingsViewController autorelease];
}

@end
