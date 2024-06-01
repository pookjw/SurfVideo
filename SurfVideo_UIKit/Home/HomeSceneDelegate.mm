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

@interface HomeSceneDelegate ()
@end

@implementation HomeSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:static_cast<UIWindowScene *>(scene)];
    [window setMrui_debugOptions:(1 << 0) ^ (1 << 1) ^ (1 << 2) ^ (1 << 3) ^ (1 << 4)];
    
    [window _requestSeparatedState:1 withReason:@"_UIViewSeparatedStateRequestReasonUnspecified"];
    
    HomeViewController *rootViewController = [HomeViewController new];
    
    window.rootViewController = rootViewController;
    window.tintColor = UIColor.systemPinkColor;
    [rootViewController release];
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
