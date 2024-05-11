//
//  ProjectsWindow.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "ProjectsWindow.hpp"
#import "ProjectsViewController.hpp"
#import "PopoverTransition.hpp"
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/PHPickerConfiguration+onlyReturnsIdentifiers.hpp>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface ProjectsWindow () <NSToolbarDelegate, PHPickerViewControllerDelegate>
@property (class, readonly, nonatomic) NSToolbarIdentifier toolbarIdentifier;
@property (class, readonly, nonatomic) NSToolbarItemIdentifier addToolbarItemIdentifier;
@property (retain, readonly, nonatomic) ProjectsViewController *projectsViewController;
@property (retain, readonly, nonatomic) NSToolbarItem *addToolbarItem;
@end

@implementation ProjectsWindow

@synthesize projectsViewController = _projectsViewController;
@synthesize addToolbarItem = _addToolbarItem;

+ (NSToolbarIdentifier)toolbarIdentifier {
    return @"ProjectsWindow.toolbarIdentifier";
}

+ (NSToolbarItemIdentifier)addToolbarItemIdentifier {
    return @"ProjectsWindow.addToolbarItem";
}

- (instancetype)init {
    self = [self initWithContentRect:NSMakeRect(0., 0., 600., 400.)
                           styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView
                             backing:NSBackingStoreBuffered
                               defer:YES];
    
    if (self) {
        self.title = @"Projects";
        self.contentViewController = self.projectsViewController;
        self.toolbar = [self makeToolbar];
        self.contentMinSize = NSMakeSize(400., 300.);
    }
    
    return self;
}

- (void)dealloc {
    [_projectsViewController release];
    [_addToolbarItem release];
    [super dealloc];
}

- (ProjectsViewController *)projectsViewController {
    if (auto projectsViewController = _projectsViewController) return projectsViewController;
    
    ProjectsViewController *projectsViewController = [ProjectsViewController new];
    _projectsViewController = [projectsViewController retain];
    
    return [projectsViewController autorelease];
}

- (NSToolbarItem *)addToolbarItem {
    if (auto addToolbarItem = _addToolbarItem) return addToolbarItem;
    
    NSToolbarItem *addToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[ProjectsWindow addToolbarItemIdentifier]];
    
    addToolbarItem.target = self;
    addToolbarItem.action = @selector(addToolbarItemDidTrigger:);
    addToolbarItem.image = [NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:nil];
    
    _addToolbarItem = [addToolbarItem retain];
    return [addToolbarItem autorelease];
}

- (NSToolbar *)makeToolbar __attribute__((objc_direct)) {
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:[ProjectsWindow toolbarIdentifier]];
    
    toolbar.delegate = self;
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    toolbar.allowsUserCustomization = NO;
    
    return [toolbar autorelease];
}

- (void)addToolbarItemDidTrigger:(NSToolbarItem *)sender {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    pickerViewController.view.frame = NSMakeRect(0., 0., 800., 600.);
    
    PopoverTransition *animator = [[PopoverTransition alloc] initWithRelativeToolbarItem:sender behavior:NSPopoverBehaviorSemitransient];
    
    [self.contentViewController presentViewController:pickerViewController animator:animator];
    [pickerViewController release];
    [animator release];
}


#pragma mark - NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:[ProjectsWindow addToolbarItemIdentifier]]) {
        return self.addToolbarItem;
    } else {
        return nil;
    }
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        [ProjectsWindow addToolbarItemIdentifier]
    ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        [ProjectsWindow addToolbarItemIdentifier]
    ];
}

- (NSSet<NSToolbarItemIdentifier> *)toolbarImmovableItemIdentifiers:(NSToolbar *)toolbar {
    return [NSSet setWithObject:[ProjectsWindow addToolbarItemIdentifier]];
}


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [self.contentViewController dismissViewController:picker];
    [self.projectsViewController didFinishPicking:results];
}

@end
