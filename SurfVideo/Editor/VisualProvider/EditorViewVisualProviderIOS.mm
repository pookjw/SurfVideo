//
//  EditorViewVisualProviderIOS.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import "EditorViewVisualProviderIOS.hpp"

#if TARGET_OS_IOS

__attribute__((objc_direct_members))
@interface EditorViewVisualProviderIOS ()
@property (retain, readonly, nonatomic) UIBarButtonItem *dismissBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *exportBarButtonItem;
@end

@implementation EditorViewVisualProviderIOS

@synthesize dismissBarButtonItem = _dismissBarButtonItem;
@synthesize addBarButtonItem = _addBarButtonItem;
@synthesize exportBarButtonItem = _exportBarButtonItem;

- (void)dealloc {
    [_dismissBarButtonItem release];
    [_addBarButtonItem release];
    [_exportBarButtonItem release];
    [super dealloc];
}

- (void)editorViewController_viewDidLoad {
    [self setupViewAttibutes];
    [self setupTrailingItemGroups];
    [self setupViewControllers];
}

- (void)setupViewAttibutes __attribute__((objc_direct)) {
    self.editorViewController.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)setupTrailingItemGroups __attribute__((objc_direct)) {
    UIBarButtonItemGroup *leadingItemGroup = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[self.addBarButtonItem, self.exportBarButtonItem] representativeItem:nil];
    UIBarButtonItemGroup *trailingItemGroup = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[self.dismissBarButtonItem] representativeItem:nil];
    
    UINavigationItem *navigationItem = self.editorViewController.navigationItem;
    
    navigationItem.leadingItemGroups = @[leadingItemGroup];
    [leadingItemGroup release];
    navigationItem.trailingItemGroups = @[trailingItemGroup];
    [trailingItemGroup release];
}

- (void)setupViewControllers __attribute__((objc_direct)) {
    EditorViewController *editorViewController = self.editorViewController;
    EditorPlayerViewController *playerViewController = self.playerViewController;
    EditorTrackViewController *trackViewController = self.trackViewController;
    
    [editorViewController addChildViewController:playerViewController];
    [editorViewController addChildViewController:trackViewController];
    
    UIView *editorView = editorViewController.view;
    UIView *playerView = playerViewController.view;
    UIView *trackView = trackViewController.view;
    
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    trackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [editorView addSubview:playerView];
    [editorView addSubview:trackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:editorView.safeAreaLayoutGuide.topAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:editorView.safeAreaLayoutGuide.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:editorView.safeAreaLayoutGuide.trailingAnchor],
        [playerView.heightAnchor constraintEqualToAnchor:editorView.heightAnchor multiplier:0.3],
        [trackView.topAnchor constraintEqualToAnchor:playerView.bottomAnchor],
        [trackView.leadingAnchor constraintEqualToAnchor:editorView.leadingAnchor],
        [trackView.trailingAnchor constraintEqualToAnchor:editorView.trailingAnchor],
        [trackView.bottomAnchor constraintEqualToAnchor:editorView.bottomAnchor]
    ]];
    
    [playerViewController didMoveToParentViewController:editorViewController];
    [trackViewController didMoveToParentViewController:editorViewController];
}

- (UIBarButtonItem *)dismissBarButtonItem {
    if (auto dismissBarButtonItem = _dismissBarButtonItem) return dismissBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *dismissAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"xmark"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.editorViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIBarButtonItem *dismissBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:dismissAction];
    
    _dismissBarButtonItem = [dismissBarButtonItem retain];
    return [dismissBarButtonItem autorelease];
}

- (UIBarButtonItem *)addBarButtonItem {
    if (auto addBarButtonItem = _addBarButtonItem) return addBarButtonItem;
    
    __weak auto weakSelf = self;
    
    //
    
    UIAction *addVideoClipFromPhotoPickerAction = [UIAction actionWithTitle:@"Photo Picker" image:[UIImage systemImageNamed:@"photo"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate didSelectPhotoPickerForAddingVideoClipWithEditorViewVisualProvider:weakSelf];
    }];
    
    UIAction *addVideoClipFromDocumentBrowserAction = [UIAction actionWithTitle:@"File Picker" image:[UIImage systemImageNamed:@"doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate didSelectDocumentBrowserForAddingVideoClipWithEditorViewVisualProvider:weakSelf];
    }];
    
    UIMenu *addVideoClipMenu = [UIMenu menuWithTitle:@"Add Video" image:[UIImage systemImageNamed:@"photo.badge.plus.fill"] identifier:nil options:0 children:@[
        addVideoClipFromPhotoPickerAction,
        addVideoClipFromDocumentBrowserAction
    ]];
    
    //
    
    UIAction *addAudioClipFromPhotoPickerAction = [UIAction actionWithTitle:@"Photo Picker" image:[UIImage systemImageNamed:@"photo"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate didSelectPhotoPickerForAddingAudioClipWithEditorViewVisualProvider:weakSelf];
    }];
    
    UIAction *addAudioClipFromDocumentBrowserAction = [UIAction actionWithTitle:@"File Picker" image:[UIImage systemImageNamed:@"doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate didSelectDocumentBrowserForAddingAudioClipWithEditorViewVisualProvider:weakSelf];
    }];
    
    UIMenu *addAudioClipMenu = [UIMenu menuWithTitle:@"Add Audio" image:[UIImage systemImageNamed:@"music.note"] identifier:nil options:0 children:@[
        addAudioClipFromPhotoPickerAction,
        addAudioClipFromDocumentBrowserAction
    ]];
    
    //
    
    // divier를 넣기 위함
    UIMenu *addClipMenu = [UIMenu menuWithTitle:[NSString string] 
                                          image:nil
                                     identifier:0
                                        options:UIMenuOptionsDisplayInline
                                       children:@[
        addVideoClipMenu,
        addAudioClipMenu
    ]];
    
    //
    
    UIAction *addCaptionAction = [UIAction actionWithTitle:@"Add Caption" image:[UIImage systemImageNamed:@"plus.bubble.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate didSelectAddCaptionWithEditorViewVisualProvider:weakSelf];
    }];
    
    UIMenu *addCaptionMenu = [UIMenu menuWithTitle:[NSString string] 
                                             image:nil
                                        identifier:0
                                           options:UIMenuOptionsDisplayInline
                                          children:@[addCaptionAction]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        addClipMenu,
        addCaptionMenu
    ]];
    
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus"] menu:menu];
    
    _addBarButtonItem = [addBarButtonItem retain];
    
    return [addBarButtonItem autorelease];
}

- (UIBarButtonItem *)exportBarButtonItem {
    if (auto exportBarButtonItem = _exportBarButtonItem) return exportBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *exportWithHighQualityAction = [UIAction actionWithTitle:@"High" image:[UIImage systemImageNamed:@"3.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate editorViewVisualProvider:weakSelf didSelectExportWithQuality:EditorServiceExportQualityHigh];
    }];
    
    UIAction *exportWithMediumQualityAction = [UIAction actionWithTitle:@"Medium" image:[UIImage systemImageNamed:@"2.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate editorViewVisualProvider:weakSelf didSelectExportWithQuality:EditorServiceExportQualityMedium];
    }];
    
    UIAction *exportWithLowQualityAction = [UIAction actionWithTitle:@"Low" image:[UIImage systemImageNamed:@"1.lane"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.delegate editorViewVisualProvider:weakSelf didSelectExportWithQuality:EditorServiceExportQualityLow];
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        exportWithHighQualityAction,
        exportWithMediumQualityAction,
        exportWithLowQualityAction
    ]];
    
    UIBarButtonItem *exportBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"] menu:menu];
    
    _exportBarButtonItem = [exportBarButtonItem retain];
    return [exportBarButtonItem autorelease];
}

@end

#endif
