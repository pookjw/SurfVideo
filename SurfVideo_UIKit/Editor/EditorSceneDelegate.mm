//
//  EditorSceneDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorSceneDelegate.hpp"
#import "EditorViewController.hpp"
#import "UIWindow+Private.h"
#import <SurfVideoCore/constants.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@implementation EditorSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // TODO: stateRestorationActivity
    if (connectionOptions.userActivities.count == 0) return;
    
    UIWindowScene *windowScene = static_cast<UIWindowScene *>(scene);
    windowScene.sizeRestrictions.minimumSize = CGSizeMake(1280.f, 500.f);
    
#if TARGET_OS_VISION
    reinterpret_cast<void (*)(id, SEL, CGSize, id, id)>(objc_msgSend)(windowScene, sel_registerName("mrui_requestResizeToSize:options:completion:"), CGSizeMake(1280.f, 500.f), nil, ^(CGSize size, NSError * _Nullable error) {
        
    });
#endif
    
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    EditorViewController *editorViewController = [[EditorViewController alloc] initWithUserActivities:connectionOptions.userActivities];
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editorViewController];
//    [editorViewController release];
//    navigationController.navigationBar.prefersLargeTitles = YES;
    window.rootViewController = editorViewController;
    [editorViewController release];
    window.tintColor = UIColor.systemCyanColor;
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
