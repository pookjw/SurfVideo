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
#import <TargetConditionals.h>

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
            return [configuration autorelease];
        }
#if TARGET_OS_VISION
        else if ([activityType isEqualToString:ImmersiveEffectSceneUserActivityType]) {
            UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
            configuration.delegateClass = ImmersiveEffectSceneDelegate.class;
            return [configuration autorelease];
        }
#endif
    }
    
    UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
    configuration.delegateClass = HomeSceneDelegate.class;
    return [configuration autorelease];
}

@end
