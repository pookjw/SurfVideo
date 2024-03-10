//
//  SettingsViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import "SettingsViewController.hpp"

__attribute__((objc_direct_members))
@interface SettingsViewController ()
@end

@implementation SettingsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_SettingsViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_SettingsViewController];
    }
    
    return self;
}

- (void)commonInit_SettingsViewController __attribute__((objc_direct)) {
    UITabBarItem *tabBarItem = self.tabBarItem;
    tabBarItem.title = @"Settings";
    tabBarItem.image = [UIImage systemImageNamed:@"gearshape"];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Settings";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}

@end
