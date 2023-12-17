//
//  EditorTrackCollectionViewLayout.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import <UIKit/UIKit.h>
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

@class EditorTrackCollectionViewLayout;
@protocol EditorTrackCollectionViewLayoutDelegate <NSObject>
- (EditorTrackSectionModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath;
@end

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout : UICollectionViewLayout
@property (weak, nonatomic) id<EditorTrackCollectionViewLayoutDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
