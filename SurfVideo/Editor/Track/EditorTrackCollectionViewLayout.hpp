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
- (NSUInteger)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout numberOfItemsForSectionIndex:(NSInteger)index;
- (EditorTrackSectionModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath;
@end

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout : UICollectionViewCompositionalLayout
@property (weak, nonatomic) id<EditorTrackCollectionViewLayoutDelegate> delegate;
- (instancetype)initWithDelegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
