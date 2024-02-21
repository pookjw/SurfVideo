//
//  EditorMenuViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import "EditorMenuViewController.hpp"
#import "UIView+Private.h"
#import "UIAlertController+Private.h"
#import "UIAlertController+SetCustomView.hpp"

__attribute__((objc_direct_members))
@interface EditorMenuViewController ()
@property (retain, readonly, nonatomic) UIStackView *stackView;
@property (retain, readonly, nonatomic) UIButton *addCaptionButton;
@property (retain, readonly, nonatomic) EditorService *editorService;
@end

@implementation EditorMenuViewController

@synthesize stackView = _stackView;
@synthesize addCaptionButton = _addCaptionButton;

- (instancetype)initWithEditorService:(EditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [editorService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_stackView release];
    [_addCaptionButton release];
    [_editorService release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.stackView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
    [self.stackView addArrangedSubview:self.addCaptionButton];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectNull];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentCenter;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)addCaptionButton {
    if (auto addCaptionButton = _addCaptionButton) return addCaptionButton;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"plus.bubble.fill"];
    
    __block auto unretained = self;
    UIAction *primaryAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained presentAddCaptionAlertController];
    }];
    
    UIButton *addCaptionButton = [UIButton buttonWithConfiguration:configuration primaryAction:primaryAction];
    _addCaptionButton = [addCaptionButton retain];
    
    return addCaptionButton;
}

- (void)presentAddCaptionAlertController __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Test" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.image = [UIImage systemImageNamed:@"plus.bubble.fill"];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectNull];
    textView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2f];
    textView.textColor = UIColor.whiteColor;
    textView.layer.cornerRadius = 8.f;
    [alertController sv_setContentView:textView];
    [textView release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    EditorService *editorService = self.editorService;
    UIAlertAction *addCaptionAction = [UIAlertAction actionWithTitle:@"Add Caption" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [editorService appendCaptionWithString:textView.text];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
