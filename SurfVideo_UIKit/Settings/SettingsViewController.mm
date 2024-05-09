//
//  SettingsViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import "SettingsViewController.hpp"
#import "SettingsViewModel.hpp"
#import <SurfVideoCore/SVProjectsManager.hpp>
#import "UIAlertController+Private.h"
#import "UIViewController+OpenURL.hpp"

__attribute__((objc_direct_members))
@interface SettingsViewController () <UICollectionViewDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *listCellRegistration;
@property (retain, readonly, nonatomic) UICollectionViewSupplementaryRegistration *listSectionHeaderSupplementaryRegistration;
@property (retain, readonly, nonatomic) UICollectionViewSupplementaryRegistration *listSectionFooterSupplementaryRegistration;
@property (retain, readonly, nonatomic) SettingsViewModel *viewModel;
@end

@implementation SettingsViewController

@synthesize collectionView = _collectionView;
@synthesize listCellRegistration = _listCellRegistration;
@synthesize listSectionHeaderSupplementaryRegistration = _listSectionHeaderSupplementaryRegistration;
@synthesize listSectionFooterSupplementaryRegistration = _listSectionFooterSupplementaryRegistration;
@synthesize viewModel = _viewModel;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_SettingsViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_SettingsViewController];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_listCellRegistration release];
    [_listSectionHeaderSupplementaryRegistration release];
    [_listSectionFooterSupplementaryRegistration release];
    [_viewModel release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel loadDataSourceWithCompletionHandler:nil];
}

- (void)commonInit_SettingsViewController __attribute__((objc_direct)) {
    UITabBarItem *tabBarItem = self.tabBarItem;
    tabBarItem.title = @"Settings";
    tabBarItem.image = [UIImage systemImageNamed:@"gearshape"];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Settings";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    listConfiguration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    listConfiguration.footerMode = UICollectionLayoutListFooterModeSupplementary;
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (UICollectionViewCellRegistration *)listCellRegistration {
    if (auto listCellRegistration = _listCellRegistration) return listCellRegistration;
    
    UICollectionViewCellRegistration *listCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, SettingsItemModel *item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        
        switch (item.type) {
            case SettingsItemModelTypeCleanupUnusedFootages:
                contentConfiguration.text = @"Cleanup Unused Footages";
                contentConfiguration.image = [UIImage systemImageNamed:@"trash"];
                break;
            case SettingsItemModelTypeDeveloperX:
                contentConfiguration.text = @"X";
                contentConfiguration.secondaryText = @"@_silgen_name";
                contentConfiguration.image = [UIImage imageNamed:@"x"];
                contentConfiguration.imageProperties.maximumSize = CGSizeMake(50.f, 50.f);
                break;
            case SettingsItemModelTypeDeveloperGitHub:
                contentConfiguration.text = @"GitHub";
                contentConfiguration.secondaryText = @"@pookjw";
                contentConfiguration.image = [UIImage imageNamed:@"github"];
                contentConfiguration.imageProperties.maximumSize = CGSizeMake(50.f, 50.f);
                break;
            default:
                break;
        }
        
        cell.contentConfiguration = contentConfiguration;
    }];
    
    _listCellRegistration = [listCellRegistration retain];
    return listCellRegistration;
}

- (UICollectionViewSupplementaryRegistration *)listSectionHeaderSupplementaryRegistration {
    if (auto listSectionHeaderSupplementaryRegistration = _listSectionHeaderSupplementaryRegistration) return listSectionHeaderSupplementaryRegistration;
    
    __weak auto weakSelf = self;
    
    UICollectionViewSupplementaryRegistration *listSectionHeaderSupplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:UICollectionViewListCell.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        SettingsSectionModel * _Nullable sectionModel = [weakSelf.viewModel queue_sectionModelAtIndex:indexPath.section];
        
        if (sectionModel == nil) {
            supplementaryView.contentConfiguration = nil;
            return;
        }
        
        UIListContentConfiguration *contentConfiguration = [supplementaryView defaultContentConfiguration];
        
        switch (sectionModel.type) {
            case SettingsSectionModelTypeMiscellaneous: 
                contentConfiguration.text = @"Miscellaneous";
                break;
            case SettingsSectionModelTypeAbout:
                contentConfiguration.text = @"About";
                break;
            default:
                break;
        }
        
        supplementaryView.contentConfiguration = contentConfiguration;
    }];
    
    _listSectionHeaderSupplementaryRegistration = [listSectionHeaderSupplementaryRegistration retain];
    return listSectionHeaderSupplementaryRegistration;
}

- (UICollectionViewSupplementaryRegistration *)listSectionFooterSupplementaryRegistration {
    if (auto listSectionFooterSupplementaryRegistration = _listSectionFooterSupplementaryRegistration) return listSectionFooterSupplementaryRegistration;
    
    __weak auto weakSelf = self;
    
    UICollectionViewSupplementaryRegistration *listSectionFooterSupplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:UICollectionViewListCell.class elementKind:UICollectionElementKindSectionFooter configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        SettingsSectionModel * _Nullable sectionModel = [weakSelf.viewModel queue_sectionModelAtIndex:indexPath.section];
        
        if (sectionModel == nil) {
            supplementaryView.contentConfiguration = nil;
            return;
        }
        
        UIListContentConfiguration *contentConfiguration = [supplementaryView defaultContentConfiguration];
        
        switch (sectionModel.type) {
            case SettingsSectionModelTypeAbout: {
                contentConfiguration.textProperties.alignment = UIListContentTextAlignmentCenter;
                
                NSDictionary *infoDictionary = NSBundle.mainBundle.infoDictionary;
                
                NSString *appName;
                if (id displayName = infoDictionary[@"CFBundleDisplayName"]) {
                    appName = displayName;
                } else {
                    appName = NSProcessInfo.processInfo.processName;
                }
                
                contentConfiguration.text = [NSString stringWithFormat:@"%@ - %@ (%@)", appName, infoDictionary[@"CFBundleShortVersionString"], infoDictionary[@"CFBundleVersion"]];
                break;
            }
            default:
                break;
        }
        
        supplementaryView.contentConfiguration = contentConfiguration;
    }];
    
    _listSectionFooterSupplementaryRegistration = [listSectionFooterSupplementaryRegistration retain];
    return listSectionFooterSupplementaryRegistration;
}

- (SettingsViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    SettingsViewModel *viewModel = [[SettingsViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<SettingsSectionModel *, SettingsItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    auto listCellRegistration = self.listCellRegistration;
    auto listSectionHeaderSupplementaryRegistration = self.listSectionHeaderSupplementaryRegistration;
    auto listSectionFooterSupplementaryRegistration = self.listSectionFooterSupplementaryRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<SettingsSectionModel *, SettingsItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:listCellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    dataSource.supplementaryViewProvider = ^UICollectionReusableView * _Nullable(UICollectionView * _Nonnull collectionView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        if ([elementKind isEqualToString:listSectionHeaderSupplementaryRegistration.elementKind]) {
            return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:listSectionHeaderSupplementaryRegistration forIndexPath:indexPath];
        } else if ([elementKind isEqualToString:listSectionFooterSupplementaryRegistration.elementKind]) {
            return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:listSectionFooterSupplementaryRegistration forIndexPath:indexPath];
        } else {
            return nil;
        }
    };
    
    return [dataSource autorelease];
}

- (void)presentCleanedFootageAlertWithCount:(NSInteger)count __attribute__((objc_direct)) {
    NSString *message = [NSString stringWithFormat:@"Clenaed footages count: %ld", count];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Done" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    alert.image = [UIImage systemImageNamed:@"xmark.bin.fill"];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:doneAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    __weak auto weakSelf = self;
    
    [self.viewModel itemModelFromIndexPath:indexPath completionHandler:^(SettingsItemModel * _Nullable itemModel) {
        if (itemModel == nil) return;
        
        switch (itemModel.type) {
            case SettingsItemModelTypeCleanupUnusedFootages: {
                [SVProjectsManager.sharedInstance cleanupFootagesWithCompletionHandler:^(NSInteger cleanedUpFootagesCount, NSError * _Nullable error) {
                    assert(!error);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf presentCleanedFootageAlertWithCount:cleanedUpFootagesCount];
                    });
                }];
                break;
            }
            case SettingsItemModelTypeDeveloperX: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf sv_openURL:[NSURL URLWithString:@"https://x.com/_silgen_name"] completionHandler:nil];
                });
                break;
            }
            case SettingsItemModelTypeDeveloperGitHub: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf sv_openURL:[NSURL URLWithString:@"https://github.com/pookjw"] completionHandler:nil];
                });
                break;
            }
            default:
                break;
        }
    }];
}

@end
