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
    
    __weak auto weakSelf = self;
    
    UIAction *highQualityAction = [UIAction actionWithTitle:@"High" image:[UIImage systemImageNamed:@"3.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto retainedSelf = weakSelf;
        if (auto retainedDelegate = retainedSelf.delegate) {
            [retainedDelegate editorExportButtonViewController:retainedSelf didTriggerButtonWithExportQuality:EditorServiceExportQualityHigh];
        }
    }];
    
    UIAction *mediumQualityAction = [UIAction actionWithTitle:@"Medium" image:[UIImage systemImageNamed:@"2.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto retainedSelf = weakSelf;
        if (auto retainedDelegate = retainedSelf.delegate) {
            [retainedDelegate editorExportButtonViewController:retainedSelf didTriggerButtonWithExportQuality:EditorServiceExportQualityMedium];
        }
    }];
    
    UIAction *lowQualityAction = [UIAction actionWithTitle:@"Low" image:[UIImage systemImageNamed:@"1.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto retainedSelf = weakSelf;
        if (auto retainedDelegate = retainedSelf.delegate) {
            [retainedDelegate editorExportButtonViewController:retainedSelf didTriggerButtonWithExportQuality:EditorServiceExportQualityLow];
        }
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        highQualityAction,
        mediumQualityAction,
        lowQualityAction
    ]];
    
    UIButton *button = [UIButton new];
    button.configuration = configuration;
    button.menu = menu;
    button.showsMenuAsPrimaryAction = YES;
    [button sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
    
    _button = [button retain];
    return button;
}

@end
