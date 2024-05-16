//
//  EditorTrackViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <AVFoundation/AVFoundation.h>
#import <SurfVideoCore/SVEditorService.hpp>
#import <SurfVideoCore/EditorTrackSectionModel.hpp>
#import <SurfVideoCore/EditorTrackItemModel.hpp>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface EditorTrackViewModel : NSObject
@property (assign, atomic, readonly) CMTime durationTime;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
#if TARGET_OS_IPHONE
- (instancetype)initWithEditorService:(SVEditorService *)editorService dataSource:(UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
#elif TARGET_OS_OSX
- (instancetype)initWithEditorService:(SVEditorService *)editorService dataSource:(NSCollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)dataSource NS_DESIGNATED_INITIALIZER;
#endif
- (void)removeTrackSegmentWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)removeCaptionWithItemModel:(EditorTrackItemModel *)itemModel completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (NSUInteger)queue_numberOfItemsAtSectionIndex:(NSUInteger)index;
- (EditorTrackSectionModel * _Nullable)queue_sectionModelAtIndex:(NSInteger)index;
- (EditorTrackItemModel * _Nullable)queue_itemModelAtIndexPath:(NSIndexPath *)indexPath;
- (void)itemModelAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(EditorTrackItemModel * _Nullable itemModel))completionHandler;
- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel attributedString:(NSAttributedString *)attributedString completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)editCaptionWithItemModel:(EditorTrackItemModel *)itemModel startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;

- (void)trimVideoClipWithItemModel:(EditorTrackItemModel *)itemModel sourceTrimTimeRange:(CMTimeRange)sourceTrimTimeRange completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
