//
//  EditorTrackCollectionViewLayout.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import <Cocoa/Cocoa.h>
#import <CoreMedia/CoreMedia.h>
#import <SurfVideoCore/EditorTrackSectionModel.hpp>
#import <SurfVideoCore/EditorTrackItemModel.hpp>

NS_ASSUME_NONNULL_BEGIN

@class EditorTrackCollectionViewLayout;
@protocol EditorTrackCollectionViewLayoutDelegate <NSObject>
- (EditorTrackSectionModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath;
@end

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout : NSCollectionViewLayout
@property (assign, nonatomic) CGFloat pixelPerSecond;
@property (weak, nonatomic) id<EditorTrackCollectionViewLayoutDelegate> _Nullable delegate;
- (CGFloat)contentOffsetXFromTime:(CMTime)time;
- (CMTime)timeFromContentOffsetX:(CGFloat)contentOffsetX;
@end

NS_ASSUME_NONNULL_END
