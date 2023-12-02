//
//  AppDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "AppDelegate.hpp"
#import "HomeSceneDelegate.hpp"
#import "EditorWindowScene.hpp"
#import "constants.hpp"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    for (NSUserActivity *userActivity in options.userActivities) {
        if ([userActivity.activityType isEqualToString:kEditorWindowSceneUserActivityType]) {
            UISceneConfiguration *configuration = connectingSceneSession.configuration;
            configuration.delegateClass = EditorWindowScene.class;
            return configuration;
        }
    }
    
    UISceneConfiguration *configuration = connectingSceneSession.configuration;
    configuration.delegateClass = HomeSceneDelegate.class;
    return configuration;
}

@end
