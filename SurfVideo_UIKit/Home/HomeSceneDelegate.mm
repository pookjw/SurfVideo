//
//  HomeSceneDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "HomeSceneDelegate.hpp"
#import "HomeViewController.hpp"
#import "UIWindow+Private.h"
#import "UIView+Private.h"
#import "CALayer+Private.h"
#import <TargetConditionals.h>

@interface HomeSceneDelegate ()
@end

@implementation HomeSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:static_cast<UIWindowScene *>(scene)];
    
    HomeViewController *rootViewController = [HomeViewController new];
    
    window.rootViewController = rootViewController;
    window.tintColor = UIColor.systemPinkColor;
    [rootViewController release];
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
