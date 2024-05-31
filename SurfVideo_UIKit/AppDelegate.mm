//
//  AppDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "AppDelegate.hpp"
#import "HomeSceneDelegate.hpp"
#import "EditorSceneDelegate.hpp"
#import "ImmersiveEffectSceneDelegate.hpp"
#import <SurfVideoCore/constants.hpp>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    for (NSUserActivity *userActivity in options.userActivities) {
        NSString *activityType = userActivity.activityType;
        
        if ([activityType isEqualToString:EditorSceneUserActivityType] && userActivity.userInfo != nil) {
            UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
            configuration.delegateClass = EditorSceneDelegate.class;
            connectingSceneSession.userInfo = @{SessionUserActivityKey: userActivity};
            return [configuration autorelease];
        } else if ([activityType isEqualToString:ImmersiveEffectSceneUserActivityType]) {
            UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
            configuration.delegateClass = ImmersiveEffectSceneDelegate.class;
            connectingSceneSession.userInfo = @{SessionUserActivityKey: userActivity};
            return [configuration autorelease];
        }
    }
    
    UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
    configuration.delegateClass = HomeSceneDelegate.class;
    return [configuration autorelease];
}

@end
