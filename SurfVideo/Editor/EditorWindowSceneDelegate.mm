//
//  EditorWindowSceneDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorWindowSceneDelegate.hpp"
#import "EditorViewController.hpp"
#import "constants.hpp"

@implementation EditorWindowSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (connectionOptions.userActivities.count == 0) return;
    
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:static_cast<UIWindowScene *>(scene)];
    EditorViewController *editorViewController = [[EditorViewController alloc] initWithUserActivities:connectionOptions.userActivities];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editorViewController];
    [editorViewController release];
    navigationController.navigationBar.prefersLargeTitles = YES;
    window.rootViewController = navigationController;
    [navigationController release];
    window.tintColor = UIColor.systemCyanColor;
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
