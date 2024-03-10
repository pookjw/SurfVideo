//
//  EditorExportButtonViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "EditorExportButtonViewController.hpp"
#import "UIView+Private.h"
#import "UIViewController+PlatterOrnament.hpp"
#include <random>
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface EditorExportButtonViewController ()
@property (retain, readonly, nonatomic) UIButton *button;
@end

@implementation EditorExportButtonViewController

@synthesize button = _button;

- (void)dealloc {
    [_button release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.button;
}

- (UIButton *)button {
    if (auto button = _button) return button;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = @"Export";
    configuration.image = [UIImage systemImageNamed:@"square.and.arrow.down"];
    
    UIButton *button = [UIButton new];
    button.configuration = configuration;
    [button addTarget:self action:@selector(buttonDidTrigger:) forControlEvents:UIControlEventTouchUpInside];
    [button sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
    
    _button = [button retain];
    return button;
}

- (void)buttonDidTrigger:(UIButton *)sender {
    if (auto retainedDelegate = self.delegate) {
        [retainedDelegate editorExportButtonViewControllerDidTriggerButton:self];
    }
}

@end
