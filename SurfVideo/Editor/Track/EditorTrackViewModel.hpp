//
//  EditorTrackViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EditorService.hpp"
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewModel : NSObject
@property (assign, atomic, readonly) CMTime durationTime;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(EditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
- (void)removeVideoTrackSegmentWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)removeCaptionWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSUInteger)queue_numberOfItemsAtSectionIndex:(NSUInteger)index;
- (EditorTrackSectionModel * _Nullable)queue_sectionModelAtIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)queue_itemModelAtIndexPath:(NSIndexPath *)indexPath;
- (void)itemModelAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorTrackItemModel * _Nullable itemModel))completionHandler;
- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel attributedString:(NSAttributedString *)attributedString completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
