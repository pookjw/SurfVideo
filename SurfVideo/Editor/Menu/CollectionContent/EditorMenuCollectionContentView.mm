//
//  EditorMenuCollectionContentView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/27/24.
//

#import "EditorMenuCollectionContentView.hpp"

__attribute__((objc_direct_members))
@interface EditorMenuCollectionContentView ()
@property (copy, nonatomic) EditorMenuCollectionContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) UIButton *primaryButton;
@end

@implementation EditorMenuCollectionContentView

@synthesize primaryButton = _primaryButton;

- (instancetype)initWithContentConfiguration:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        UIButton *primaryButton = self.primaryButton;
        primaryButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:primaryButton];
        
        self.contentConfiguration = contentConfiguration;
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_primaryButton release];
    [super dealloc];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = static_cast<EditorMenuCollectionContentConfiguration *>(configuration);
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:EditorMenuCollectionContentConfiguration.class];
}

- (UIButton *)primaryButton {
    if (auto primaryButton = _primaryButton) return primaryButton;
    
    UIButton *primaryButton = [[UIButton alloc] initWithFrame:self.bounds];
    _primaryButton = [primaryButton retain];
    
    return [primaryButton autorelease];
}

- (void)setContentConfiguration:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    UIButton *primaryButton = self.primaryButton;
    primaryButton.menu = nil;
    primaryButton.showsMenuAsPrimaryAction = NO;
    primaryButton.configuration = nil;
    [primaryButton removeTarget:self action:@selector(primaryButtonDidTrigger:) forControlEvents:UIControlEventTouchUpInside];
    
    switch (contentConfiguration.type) {
        case EditorMenuItemModelTypeAddVideoClips: {
            UIAction *presentPhotoPickerAction = [UIAction actionWithTitle:@"Photo Picker" 
                                                                     image:[UIImage systemImageNamed:@"photo"]
                                                                identifier:nil
                                                                   handler:^(__kindof UIAction * _Nonnull action) {
                [contentConfiguration.delegate editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithPhotoPicker:contentConfiguration];
            }];
            
            UIAction *presentDocumentBrowserAction = [UIAction actionWithTitle:@"File Picker"
                                                                         image:[UIImage systemImageNamed:@"doc"]
                                                                    identifier:nil
                                                                       handler:^(__kindof UIAction * _Nonnull action) {
                [contentConfiguration.delegate editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithDocumentBrowser:contentConfiguration];
            }];
            
            UIMenu *menu = [UIMenu menuWithChildren:@[
                presentPhotoPickerAction,
                presentDocumentBrowserAction
            ]];
            
            primaryButton.menu = menu;
            primaryButton.showsMenuAsPrimaryAction = YES;
            
            UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.image = [UIImage systemImageNamed:@"photo.badge.plus.fill"];
            primaryButton.configuration = configuration;
            break;
        }
        case EditorMenuItemModelTypeAddAudioClips: {
            UIAction *presentPhotoPickerAction = [UIAction actionWithTitle:@"Photo Picker" 
                                                                     image:[UIImage systemImageNamed:@"photo"]
                                                                identifier:nil
                                                                   handler:^(__kindof UIAction * _Nonnull action) {
                [contentConfiguration.delegate editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithPhotoPicker:contentConfiguration];
            }];
            
            UIAction *presentDocumentBrowserAction = [UIAction actionWithTitle:@"File Picker"
                                                                         image:[UIImage systemImageNamed:@"doc"]
                                                                    identifier:nil
                                                                       handler:^(__kindof UIAction * _Nonnull action) {
                [contentConfiguration.delegate editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithDocumentBrowser:contentConfiguration];
            }];
            
            UIMenu *menu = [UIMenu menuWithChildren:@[
                presentPhotoPickerAction,
                presentDocumentBrowserAction
            ]];
            
            primaryButton.menu = menu;
            primaryButton.showsMenuAsPrimaryAction = YES;
            UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.image = [UIImage systemImageNamed:@"music.note"];
            primaryButton.configuration = configuration;
            break;
        }
        case EditorMenuItemModelTypeAddCaption: {
            [primaryButton addTarget:self action:@selector(primaryButtonDidTrigger:) forControlEvents:UIControlEventTouchUpInside];
            
            UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.image = [UIImage systemImageNamed:@"plus.bubble.fill"];
            primaryButton.configuration = configuration;
            break;
        }
    }
}

- (void)primaryButtonDidTrigger:(UIButton *)sender {
    EditorMenuCollectionContentConfiguration *contentConfiguration = self.contentConfiguration;
    
    switch (contentConfiguration.type) {
        case EditorMenuItemModelTypeAddCaption:
            [contentConfiguration.delegate editorMenuCollectionContentConfigurationDidSelectAddCaption:contentConfiguration];
        default:
            break;
    }
}

@end
