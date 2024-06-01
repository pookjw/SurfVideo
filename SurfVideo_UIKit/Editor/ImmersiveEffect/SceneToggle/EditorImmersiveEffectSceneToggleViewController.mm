//
//  EditorImmersiveEffectSceneToggleViewController.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "EditorImmersiveEffectSceneToggleViewController.hpp"

#if TARGET_OS_VISION

#import "UIView+Private.h"
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import <SurfVideoCore/constants.hpp>

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectSceneToggleViewController ()
@property (retain, readonly, nonatomic) UIButton *button;
@property (readonly, assign) UIScene * _Nullable immersiveSpaceScene;
@end

@implementation EditorImmersiveEffectSceneToggleViewController

@synthesize button = _button;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_ImmersiveEffectSceneToggleViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_ImmersiveEffectSceneToggleViewController];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_button release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
    [self setupButton];
}

- (void)commonInit_ImmersiveEffectSceneToggleViewController __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
}

- (void)setupButton __attribute__((objc_direct)) {
    UIButton *button = self.button;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:button];
}

- (UIButton *)button {
    if (auto button = _button) return button;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    
    if (self.immersiveSpaceScene == nil) {
        configuration.image =  [UIImage systemImageNamed:@"visionpro"];
    } else {
        configuration.image =  [UIImage systemImageNamed:@"visionpro.fill"];
    }
    
    UIButton *button = [[UIButton alloc] initWithFrame:self.view.bounds];
    
    button.configuration = configuration;
    [button addTarget:self action:@selector(buttonDidTrigger:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _button = [button retain];
    return [button autorelease];
}

- (UIScene *)immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
            return scene;
        }
    }
    
    return nil;
}

- (void)receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    if (scene == nil) return;
    
    if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
        UIButtonConfiguration *configuration = [self.button.configuration copy];
        configuration.image = [UIImage systemImageNamed:@"visionpro.fill"];
        self.button.configuration = configuration;
        [configuration release];
    }
}

- (void)receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    if (scene == nil) return;
    
    if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
        UIButtonConfiguration *configuration = [self.button.configuration copy];
        configuration.image = [UIImage systemImageNamed:@"visionpro"];
        self.button.configuration = configuration;
        [configuration release];
    }
}

- (void)buttonDidTrigger:(UIButton *)sender {
    if (UIScene *scene = self.immersiveSpaceScene) {
        [UIApplication.sharedApplication requestSceneSessionDestruction:scene.session options:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
        }];
        
        return;
    }
    
    //
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:ImmersiveEffectSceneUserActivityType];
    
    [UIApplication.sharedApplication mruiw_requestMixedImmersiveSceneWithUserActivity:userActivity completionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    
    [userActivity release];
}

@end

#endif
