//
//  EditorWindowScene.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorWindowScene.hpp"
#import "EditorViewController.hpp"
#import "constants.hpp"

@implementation EditorWindowScene

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:static_cast<UIWindowScene *>(scene)];
    EditorViewController *editorViewController = [[EditorViewController alloc] initWithUserActivities:connectionOptions.userActivities];
    UINavigationController *rootViewController = [[UINavigationController alloc] initWithRootViewController:editorViewController];
    [editorViewController release];
    rootViewController.navigationBar.prefersLargeTitles = YES;
    window.rootViewController = rootViewController;
    window.tintColor = UIColor.systemGreenColor;
    [rootViewController release];
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
