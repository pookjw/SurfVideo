//
//  UIAlertController+SetCustomView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/10/23.
//

#import "UIAlertController+SetCustomView.hpp"
#import "UIAlertController+Private.h"

@interface SV_SVC_ViewController : UIViewController {
    UIView *_contentView;
}
- (instancetype)initWithContentView:(UIView *)contentView;
@end

@implementation SV_SVC_ViewController

- (instancetype)initWithContentView:(UIView *)contentView {
    if (self = [super initWithNibName:nil bundle:nil]) {
        [_contentView release];
        _contentView = [contentView retain];
    }
    
    return self;
}

- (void)dealloc {
    [_contentView release];
    [super dealloc];
}

- (void)loadView {
    self.view = _contentView;
}

@end

@implementation UIAlertController (SetCustomView)

- (void)sv_setSeparatedHeaderView:(UIView *)separatedHeaderView {
    SV_SVC_ViewController *viewController = [[SV_SVC_ViewController alloc] initWithContentView:separatedHeaderView];
    [self _setSeparatedHeaderContentViewController:viewController];
    [viewController release];
}

- (void)sv_setHeaderView:(UIView *)headerView {
    SV_SVC_ViewController *viewController = [[SV_SVC_ViewController alloc] initWithContentView:headerView];
    [self _setHeaderContentViewController:viewController];
    [viewController release];
}

- (void)sv_setContentView:(UIView *)contentView {
    SV_SVC_ViewController *viewController = [[SV_SVC_ViewController alloc] initWithContentView:contentView];
    [self setContentViewController:viewController];
    [viewController release];
}

@end
