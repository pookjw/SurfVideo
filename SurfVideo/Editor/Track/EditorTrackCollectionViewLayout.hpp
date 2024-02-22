//
//  EditorTrackCollectionViewLayout.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/22/24.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
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
@property (assign, nonatomic) CGFloat pixelPerSecond;
@property (weak, nonatomic) id<EditorTrackCollectionViewLayoutDelegate> _Nullable delegate;
- (CGPoint)contentOffsetFromTime:(CMTime)time;
- (CMTime)timeFromContentOffset:(CGPoint)contentOffset;
@end

NS_ASSUME_NONNULL_END
