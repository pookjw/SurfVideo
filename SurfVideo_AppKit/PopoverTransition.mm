//
//  PopoverTransition.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "PopoverTransition.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface PopoverTransition ()
@property (retain, nonatomic, readonly) NSToolbarItem * _Nullable toolbarItem;
@property (assign, nonatomic, readonly) NSPopoverBehavior behavior;
@end

@implementation PopoverTransition

- (instancetype)initWithRelativeToolbarItem:(NSToolbarItem *)toolbarItem behavior:(NSPopoverBehavior)behavior {
    if (self = [super init]) {
        _toolbarItem = [toolbarItem retain];
        _behavior = behavior;
    }
    
    return self;
}

- (void)dealloc {
    [_toolbarItem release];
    [super dealloc];
}

- (void)animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSPopover *popover = [NSPopover new];
    
    popover.contentViewController = viewController;
    popover.behavior = self.behavior;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_windowDidClose:) name:NSPopoverDidCloseNotification object:popover];
    
    [popover showRelativeToToolbarItem:self.toolbarItem];
    [popover release];
}

- (void)animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    __kindof NSWindow *popoverWindow = viewController.view.window;
    
    if ([popoverWindow isKindOfClass:objc_lookUpClass("_NSPopoverWindow")]) {
        NSPopover *_popover = ((id (*)(id, SEL))objc_msgSend)(popoverWindow, sel_registerName("_popover"));
        [_popover close];
    }
}

- (void)_windowDidClose:(NSNotification *)notification {
    NSPopover *popover = notification.object;
    
    NSViewController *contentViewController = popover.contentViewController;
    
    if (contentViewController == nil) return;
    
    NSViewController *presentingViewController = contentViewController.presentingViewController;
    
    if (presentingViewController == nil) return;
    
    [presentingViewController dismissViewController:contentViewController];
}

@end
