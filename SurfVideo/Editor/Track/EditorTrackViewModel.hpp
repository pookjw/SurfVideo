//
//  EditorTrackViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EditorViewModel.hpp"
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorViewModel:(EditorViewModel *)editorViewModel dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
