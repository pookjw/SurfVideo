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
#import "EditorMenuViewModel.hpp"
#import "EditorMenuCollectionViewLayout.hpp"

__attribute__((objc_direct_members))
@interface EditorMenuViewController () <UICollectionViewDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) EditorMenuViewModel *viewModel;
@property (retain, readonly, nonatomic) EditorService *editorService;
@end

@implementation EditorMenuViewController

@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;
@synthesize viewModel = _viewModel;

- (instancetype)initWithEditorService:(EditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [editorService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_cellRegistration release];
    [_viewModel release];
    [_editorService release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self viewModel];
    [self.view sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    EditorMenuCollectionViewLayout *collectionViewLayout = [EditorMenuCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (EditorMenuViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    EditorMenuViewModel *viewModel = [[EditorMenuViewModel alloc] initWithEditorService:self.editorService dataSource:[self makeDataSource]];
    [viewModel loadDataSourceWithCompletionHandler:nil];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    auto cellRegistration = self.cellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorMenuItemModel * _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.image = item.image;
        contentConfiguration.imageProperties.tintColor = UIColor.labelColor;
        cell.contentConfiguration = contentConfiguration;
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
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
        [editorService appendCaptionWithAttributedString:textView.attributedText completionHandler:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    [self.viewModel itemModelFromIndexPath:indexPath completionHandler:^(EditorMenuItemModel * _Nullable itemModel) {
        switch (itemModel.type) {
            case EditorMenuItemModelTypeAddCaption:
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentAddCaptionAlertController];
                });
                break;
            case EditorMenuItemModelTypeEditCaption:
                NSLog(@"TODO");
                break;
            case EditorMenuItemModelTypeChangeCaptionTime:
                NSLog(@"TODO");
                break;
            default:
                break;
        }
    }];
}

@end
