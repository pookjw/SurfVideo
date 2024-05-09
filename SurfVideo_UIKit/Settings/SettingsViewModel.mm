//
//  SettingsViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import "SettingsViewModel.hpp"

__attribute__((objc_direct_members))
@interface SettingsViewModel ()
@property (retain, readonly, nonatomic) UICollectionViewDiffableDataSource<SettingsSectionModel *,SettingsItemModel *> *dataSource;
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@end

@implementation SettingsViewModel

- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<SettingsSectionModel *,SettingsItemModel *> *)dataSource {
    if (self = [super init]) {
        _dataSource = [dataSource retain];
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("SettingsViewModel", attr);
    }
    
    return self;
}

- (void)dealloc {
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_dataSource release];
    [super dealloc];
}

- (void)loadDataSourceWithCompletionHandler:(void (^)())completionHandler {
    auto dataSource = self.dataSource;
    
    dispatch_async(self.queue, ^{
        auto snapshot = [NSDiffableDataSourceSnapshot<SettingsSectionModel *, SettingsItemModel *> new];
        
        //
        
        SettingsSectionModel *miscellaneousSectionModel = [[SettingsSectionModel alloc] initWithType:SettingsSectionModelTypeMiscellaneous];
        SettingsSectionModel *aboutSectionModel = [[SettingsSectionModel alloc] initWithType:SettingsSectionModelTypeAbout];
        
        [snapshot appendSectionsWithIdentifiers:@[miscellaneousSectionModel, aboutSectionModel]];
        
        SettingsItemModel *cleanupUnusedFootagesItemModel = [[SettingsItemModel alloc] initWithType:SettingsItemModelTypeCleanupUnusedFootages];
        SettingsItemModel *developerXItemModel = [[SettingsItemModel alloc] initWithType:SettingsItemModelTypeDeveloperX];
        SettingsItemModel *developerGitHubItemModel = [[SettingsItemModel alloc] initWithType:SettingsItemModelTypeDeveloperGitHub];
        
        [snapshot appendItemsWithIdentifiers:@[cleanupUnusedFootagesItemModel] intoSectionWithIdentifier:miscellaneousSectionModel];
        [snapshot appendItemsWithIdentifiers:@[developerXItemModel, developerGitHubItemModel] intoSectionWithIdentifier:aboutSectionModel];
        
        [miscellaneousSectionModel release];
        [aboutSectionModel release];
        
        [cleanupUnusedFootagesItemModel release];
        [developerXItemModel release];
        [developerGitHubItemModel release];
        
        //
        
        [dataSource applySnapshot:snapshot animatingDifferences:YES completion:completionHandler];
        [snapshot release];
    });
}

- (void)itemModelFromIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(SettingsItemModel * _Nullable itemModel))completionHandler {
    auto dataSource = self.dataSource;
    
    dispatch_async(self.queue, ^{
        SettingsItemModel * _Nullable itemModel = [dataSource itemIdentifierForIndexPath:indexPath];
        completionHandler(itemModel);
    });
}

- (SettingsSectionModel *)queue_sectionModelAtIndex:(NSInteger)index {
    return [self.dataSource sectionIdentifierForIndex:index];
}

@end
