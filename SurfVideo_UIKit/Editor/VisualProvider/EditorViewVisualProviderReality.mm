//
//  EditorViewVisualProviderReality.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import "EditorViewVisualProviderReality.hpp"
#import "EditorExportButtonViewController.hpp"
#import "EditorMenuViewController.hpp"
#import "EditorRealityMenuViewController.hpp"
#import "ImmersiveEffect.hpp"
#import "UIScrollView+ScrollWithHandTracking.hpp"
#import <SurfVideoCore/PHPickerConfiguration+onlyReturnsIdentifiers.hpp>
#import <PhotosUI/PhotosUI.h>
#import <objc/message.h>
#import <objc/runtime.h>

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface EditorViewVisualProviderReality () <PHPickerViewControllerDelegate, EditorExportButtonViewControllerDelegate, EditorMenuViewControllerDelegate, EditorRealityMenuViewControllerDelegate>
@property (retain, readonly, nonatomic) EditorExportButtonViewController *exportButtonViewController;
@property (retain, readonly, nonatomic) EditorMenuViewController *menuViewController;
@property (retain, readonly, nonatomic) EditorRealityMenuViewController *realityMenuViewController;
@property (retain, readonly, nonatomic) PHPickerViewController *ornamentPhotoPickerViewController;
@property (retain, readonly, nonatomic) id playerOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id menuOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id realityMenuOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id photoPickerOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id exportButtonOrnament; // MRUIPlatterOrnament *
@end

@implementation EditorViewVisualProviderReality

@synthesize exportButtonViewController = _exportButtonViewController;
@synthesize menuViewController = _menuViewController;
@synthesize realityMenuViewController = _realityMenuViewController;
@synthesize ornamentPhotoPickerViewController = _ornamentPhotoPickerViewController;
@synthesize playerOrnament = _playerOrnament;
@synthesize menuOrnament = _menuOrnament;
@synthesize realityMenuOrnament = _realityMenuOrnament;
@synthesize photoPickerOrnament = _photoPickerOrnament;
@synthesize exportButtonOrnament = _exportButtonOrnament;

- (void)dealloc {
    [_exportButtonViewController release];
    [_menuViewController release];
    [_ornamentPhotoPickerViewController release];
    [_realityMenuViewController release];
    [_playerOrnament release];
    [_menuOrnament release];
    [_realityMenuOrnament release];
    [_photoPickerOrnament release];
    [_exportButtonOrnament release];
    [super dealloc];
}

- (void)editorViewController_viewDidLoad {
    [self setupViewAttibutes];
    [self setupTrackViewController];
    [self setupOrnaments];
}

- (void)playEffectsWithRenderEffects:(NSArray<SVEditorRenderEffect *> *)renderEffects {
    for (SVEditorRenderEffect *renderEffect in renderEffects) {
        BOOL valid;
        ImmersiveEffect immersiveEffect = ImmersiveEffectFromString(renderEffect.effectName, &valid);
        assert(valid);
        
        [NSNotificationCenter.defaultCenter postNotificationName:ImmersiveEffectAddEffectNotification
                                                          object:nil
                                                        userInfo:@{
            ImmersiveEffectNumberKey: @(immersiveEffect),
            ImmersiveEffectReqestIDKey: renderEffect.effectID,
            ImmersiveEffectDurationTimeValueKey: [NSValue valueWithCMTime:renderEffect.timeRange.duration]
        }];
    }
}

- (void)setupViewAttibutes __attribute__((objc_direct)) {
    self.editorViewController.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)setupTrackViewController __attribute__((objc_direct)) {
    EditorViewController *editorViewController = self.editorViewController;
    EditorTrackViewController *trackViewController = self.trackViewController;
    
    [editorViewController addChildViewController:trackViewController];
    
    UIView *trackView = trackViewController.view;
    trackView.translatesAutoresizingMaskIntoConstraints = NO;
    [editorViewController.view addSubview:trackView];
    [NSLayoutConstraint activateConstraints:@[
        [trackView.topAnchor constraintEqualToAnchor:editorViewController.view.topAnchor],
        [trackView.leadingAnchor constraintEqualToAnchor:editorViewController.view.leadingAnchor],
        [trackView.trailingAnchor constraintEqualToAnchor:editorViewController.view.trailingAnchor],
        [trackView.bottomAnchor constraintEqualToAnchor:editorViewController.view.bottomAnchor]
    ]];
    [trackViewController didMoveToParentViewController:editorViewController];
}

- (void)setupOrnaments __attribute__((objc_direct)) {
    // MRUIOrnamentsItem
    id mrui_ornamentsItem = reinterpret_cast<id (*) (id, SEL)>(objc_msgSend) (self.editorViewController, NSSelectorFromString(@"mrui_ornamentsItem"));
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), @[
        self.playerOrnament,
        self.menuOrnament,
        self.photoPickerOrnament,
        self.exportButtonOrnament,
        self.realityMenuOrnament
    ]);
}

- (EditorExportButtonViewController *)exportButtonViewController {
    if (auto exportButtonViewController = _exportButtonViewController) return exportButtonViewController;
    
    EditorExportButtonViewController *exportButtonViewController = [EditorExportButtonViewController new];
    exportButtonViewController.delegate = self;
    
    _exportButtonViewController = [exportButtonViewController retain];
    return [exportButtonViewController autorelease];
}

- (EditorMenuViewController *)menuViewController {
    if (auto menuViewController = _menuViewController) return menuViewController;
        
    EditorMenuViewController *menuViewController = [[EditorMenuViewController alloc] initWithEditorService:self.editorService];
    menuViewController.delegate = self;
    
    _menuViewController = [menuViewController retain];
    return [menuViewController autorelease];
}

- (id)playerOrnament {
    if (id playerOrnament = _playerOrnament) return playerOrnament;
    
    EditorPlayerViewController *playerViewController = self.playerViewController;
    id playerOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), playerViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(1280., 720.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.5, 1.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5f, 0.));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"_setZOffset:"), 0.);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(0., -50.));
    
    _playerOrnament = [playerOrnament retain];
    return [playerOrnament autorelease];
}

- (id)menuOrnament {
    if (id menuOrnament = _menuOrnament) return menuOrnament;
    
    EditorMenuViewController *menuViewController = self.menuViewController;
    id menuOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), menuViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(320., 80.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.5, 0.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5, 1.));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"_setZOffset:"), 50.);
    
    _menuOrnament = [menuOrnament retain];
    return [menuOrnament autorelease];
}

- (id)realityMenuOrnament {
    if (id realityMenuOrnament = _realityMenuOrnament) return realityMenuOrnament;
    
    EditorRealityMenuViewController *realityMenuViewController = self.realityMenuViewController;
    id menuOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), realityMenuViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(240., 80.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0., 0.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5, 1.));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"_setZOffset:"), 50.);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(-(160. + 20. + 240.) , 0.));
    
    _realityMenuOrnament = [menuOrnament retain];
    return [menuOrnament autorelease];
}

- (id)photoPickerOrnament {
    if (id photoPickerOrnament = _photoPickerOrnament) return photoPickerOrnament;
    
    PHPickerViewController *photoPickerViewController = self.ornamentPhotoPickerViewController;
    
    id photoPickerOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), photoPickerViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400., 600.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0., 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(1., 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"_setZOffset:"), -10.);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(50., 0.));
    
    _photoPickerOrnament = [photoPickerOrnament retain];
    return [photoPickerOrnament autorelease];
}

- (id)exportButtonOrnament {
    if (id exportButtonOrnament = _exportButtonOrnament) return exportButtonOrnament;
    
    EditorExportButtonViewController *exportButtonViewController = self.exportButtonViewController;
    
    id exportButtonOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), exportButtonViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(240., 80.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0., 0.));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5, 1.));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"_setZOffset:"), 50.);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(160. + 20., 0.));
    
    _exportButtonOrnament = [exportButtonOrnament retain];
    return [exportButtonOrnament autorelease];
}

- (EditorRealityMenuViewController *)realityMenuViewController {
    if (auto realityMenuViewController = _realityMenuViewController) return realityMenuViewController;
    
    EditorRealityMenuViewController *realityMenuViewController = [EditorRealityMenuViewController new];
    realityMenuViewController.delegate = self;
    
    _realityMenuViewController = [realityMenuViewController retain];
    return [realityMenuViewController autorelease];
}

- (PHPickerViewController *)ornamentPhotoPickerViewController {
    if (auto pickerViewController = _ornamentPhotoPickerViewController) return pickerViewController;
    
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    
    _ornamentPhotoPickerViewController = [pickerViewController retain];
    return [pickerViewController autorelease];
}


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(nonnull PHPickerViewController *)picker didFinishPicking:(nonnull NSArray<PHPickerResult *> *)results { 
    [self.delegate editorViewVisualProvider:self didFinishPickingPickerResultsForAddingVideoClip:results];
}


#pragma mark - EditorExportButtonViewControllerDelegate

- (void)editorExportButtonViewController:(nonnull EditorExportButtonViewController *)editorExportButtonViewController didTriggerButtonWithExportQuality:(EditorServiceExportQuality)exportQuality { 
    [self.delegate editorViewVisualProvider:self didSelectExportWithQuality:exportQuality];
}


#pragma mark - EditorMenuViewControllerDelegate

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithDocumentBrowser:(nonnull EditorMenuViewController *)viewController { 
    [self.delegate didSelectDocumentBrowserForAddingAudioClipWithEditorViewVisualProvider:self];
}

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithPhotoPicker:(nonnull EditorMenuViewController *)viewController { 
    [self.delegate didSelectPhotoPickerForAddingAudioClipWithEditorViewVisualProvider:self];
}

- (void)editorMenuViewControllerDidSelectAddCaption:(nonnull EditorMenuViewController *)viewController { 
    [self.delegate didSelectAddCaptionWithEditorViewVisualProvider:self];
}

- (void)editorMenuViewControllerDidSelectAddEffect:(EditorMenuViewController *)viewController {
    [self.delegate didSelectAddEffectWithEditorViewVisualProvider:self];
}

- (void)editorMenuViewControllerDidSelectAddVideoClipsWithDocumentBrowser:(nonnull EditorMenuViewController *)viewController { 
    [self.delegate didSelectDocumentBrowserForAddingVideoClipWithEditorViewVisualProvider:self];
}

- (void)editorMenuViewControllerDidSelectAddVideoClipsWithPhotoPicker:(nonnull EditorMenuViewController *)viewController { 
    [self.delegate didSelectPhotoPickerForAddingVideoClipWithEditorViewVisualProvider:self];
}


#pragma mark - EditorRealityMenuViewControllerDelegate

- (void)editorRealityMenuViewController:(EditorRealityMenuViewController *)editorRealityMenuViewController didToggleScrollingTrackViewWithHandTracking:(BOOL)enabled {
    if (enabled) {
        [self.trackViewController.collectionViewIfLoaded sv_enableHandTrackingHorizontalScrollingWithSensitivity:20.];
    } else {
        [self.trackViewController.collectionViewIfLoaded sv_disableHandTrackingHorizontalScrolling];
    }
}

@end

#endif
