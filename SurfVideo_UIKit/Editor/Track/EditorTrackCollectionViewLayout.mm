//
//  EditorTrackCollectionViewLayout.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/22/24.
//

#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackPlayHeadCollectionReusableView.hpp"
#import "EditorTrackCollectionViewLayoutAttributes.hpp"
#import "EditorTrackThumbnailPlayerCollectionReusableView.hpp"
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <vector>
#import <numeric>

OBJC_EXPORT id objc_msgSendSuper2(void);

#define LAYOUT_ATTRIBUTES_ARRAY_KEY @"layoutAttributesArray"
#define TOTAL_WIDTH_KEY @"totalWidth"
#define Y_OFFSET @"yOffset"

@interface EditorTrackCollectionViewLayout ()
@property (assign, nonatomic) CGSize collectionViewContentSize;
@property (copy, nonatomic, direct) NSArray<EditorTrackCollectionViewLayoutAttributes *> * _Nullable mainVideoTrackLayoutAttributesArray;
@property (copy, nonatomic, direct) NSArray<EditorTrackCollectionViewLayoutAttributes *> * _Nullable audioTrackLayoutAttributesArray;
@property (copy, nonatomic, direct) NSArray<EditorTrackCollectionViewLayoutAttributes *> * _Nullable captionTrackLayoutAttributesArray;
@property (copy, nonatomic, direct) NSDictionary<NSIndexPath *, EditorTrackCollectionViewLayoutAttributes *> * _Nullable mainVideoTrackDecorationLayoutAttributesByIndexPath;
@property (readonly, nonatomic, direct) EditorTrackCollectionViewLayoutAttributes *playHeadDecorationLayoutAttributes;
@end

@implementation EditorTrackCollectionViewLayout

+ (Class)layoutAttributesClass {
    return [EditorTrackCollectionViewLayoutAttributes class];
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit_EditorTrackCollectionViewLayout];
    }
    
    return self;
}

- (void)dealloc {
    [_mainVideoTrackLayoutAttributesArray release];
    [_audioTrackLayoutAttributesArray release];
    [_captionTrackLayoutAttributesArray release];
    [_mainVideoTrackDecorationLayoutAttributesByIndexPath release];
    [super dealloc];
}

- (void)prepareLayout {
    [super prepareLayout];
    
    self.mainVideoTrackLayoutAttributesArray = nil;
    self.audioTrackLayoutAttributesArray = nil;
    self.captionTrackLayoutAttributesArray = nil;
    self.mainVideoTrackDecorationLayoutAttributesByIndexPath = nil;
    
    auto _delegate = self.delegate;
    if (_delegate == nil) return;
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    CGFloat yOffset = 0.f;
    CGFloat maxWidth = 0.f;
    
    std::vector<NSInteger> sectionIndexes(numberOfSections);
    std::iota(sectionIndexes.begin(), sectionIndexes.end(), 0);
    
    std::for_each(sectionIndexes.cbegin(), sectionIndexes.cend(), [_delegate, self, &yOffset, &maxWidth](const NSInteger sectionIndex) {
        EditorTrackSectionModel *sectionModel = [_delegate editorTrackCollectionViewLayout:self sectionModelForIndex:sectionIndex];
        
        CGFloat totalWidth;
        
        switch (sectionModel.type) {
            case EditorTrackSectionModelTypeMainVideoTrack: {
                auto result = [self videoTrackLayoutInfoWithSectionModel:sectionModel
                                                            sectionIndex:sectionIndex
                                                                 yOffset:yOffset
                                                                delegate:_delegate];
                
                NSArray<EditorTrackCollectionViewLayoutAttributes *> *mainVideoTrackLayoutAttributesArray = result[LAYOUT_ATTRIBUTES_ARRAY_KEY];
                NSDictionary<NSIndexPath *, EditorTrackCollectionViewLayoutAttributes *> *mainVideoTrackDecorationLayoutAttributesByIndexPath = [self videoTrackSegmentThumbnailLayoutAttributesByIndexPathFromVideoTrackLayoutAttributesArray:mainVideoTrackLayoutAttributesArray];
                
                self.mainVideoTrackLayoutAttributesArray = mainVideoTrackLayoutAttributesArray;
                self.mainVideoTrackDecorationLayoutAttributesByIndexPath = mainVideoTrackDecorationLayoutAttributesByIndexPath;
                
                yOffset = static_cast<NSNumber *>(result[Y_OFFSET]).floatValue;
                totalWidth = static_cast<NSNumber *>(result[TOTAL_WIDTH_KEY]).floatValue;
                break;
            }
            case EditorTrackSectionModelTypeAudioTrack: {
                auto result = [self audioTrackLayoutInfoWithSectionModel:sectionModel
                                                            sectionIndex:sectionIndex
                                                                 yOffset:yOffset
                                                                delegate:_delegate];
                
                self.audioTrackLayoutAttributesArray = result[LAYOUT_ATTRIBUTES_ARRAY_KEY];
                yOffset = static_cast<NSNumber *>(result[Y_OFFSET]).floatValue;
                totalWidth = static_cast<NSNumber *>(result[TOTAL_WIDTH_KEY]).floatValue;
                break;
            }
            case EditorTrackSectionModelTypeCaptionTrack: {
                auto result = [self captionTrackLayoutInfoWithSectionModel:sectionModel
                                                            sectionIndex:sectionIndex
                                                                 yOffset:yOffset
                                                                delegate:_delegate];
                
                self.captionTrackLayoutAttributesArray = result[LAYOUT_ATTRIBUTES_ARRAY_KEY];
                yOffset = static_cast<NSNumber *>(result[Y_OFFSET]).floatValue;
                totalWidth = static_cast<NSNumber *>(result[TOTAL_WIDTH_KEY]).floatValue;
                break;
            }
            default:
                return;
        }
        
        maxWidth = std::fmaxf(maxWidth, totalWidth);
    });
    
    self.collectionViewContentSize = CGSizeMake(maxWidth, yOffset);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    EditorTrackSectionModel * _Nullable sectionModel = [self.delegate editorTrackCollectionViewLayout:self sectionModelForIndex:indexPath.section];
    
    if (sectionModel == nil) {
        return nil;
    }
    
    switch (sectionModel.type) {
        case EditorTrackSectionModelTypeMainVideoTrack:
            return self.mainVideoTrackLayoutAttributesArray[indexPath.item];
        case EditorTrackSectionModelTypeAudioTrack:
            return self.audioTrackLayoutAttributesArray[indexPath.item];
        case EditorTrackSectionModelTypeCaptionTrack:
            return self.captionTrackLayoutAttributesArray[indexPath.item];
    }
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [[[[self.mainVideoTrackLayoutAttributesArray arrayByAddingObjectsFromArray:self.captionTrackLayoutAttributesArray] arrayByAddingObject:self.playHeadDecorationLayoutAttributes] arrayByAddingObjectsFromArray:self.audioTrackLayoutAttributesArray] arrayByAddingObjectsFromArray:self.mainVideoTrackDecorationLayoutAttributesByIndexPath.allValues];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:EditorTrackPlayHeadCollectionReusableView.elementKind]) {
        return self.playHeadDecorationLayoutAttributes;
    } else if ([elementKind isEqualToString:EditorTrackThumbnailPlayerCollectionReusableView.elementKind]) {
        return self.mainVideoTrackDecorationLayoutAttributesByIndexPath[indexPath];
    } else {
        return nil;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    UICollectionViewLayoutInvalidationContext *result = [UICollectionViewLayoutInvalidationContext new];
    
    [result invalidateDecorationElementsOfKind:EditorTrackPlayHeadCollectionReusableView.elementKind atIndexPaths:@[self.playHeadDecorationLayoutAttributes.indexPath]];
    [result invalidateDecorationElementsOfKind:EditorTrackThumbnailPlayerCollectionReusableView.elementKind atIndexPaths:self.mainVideoTrackDecorationLayoutAttributesByIndexPath.allKeys];
    
    return [result autorelease];
}


# pragma mark - Custom Methods

- (CGFloat)contentOffsetXFromTime:(CMTime)time {
    return self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
}

- (CMTime)timeFromContentOffsetX:(CGFloat)contentOffsetX {
    std::int32_t timescale = 1000000L;
    return CMTimeMake((contentOffsetX / self.pixelPerSecond) * timescale, timescale);
}

- (void)setPixelPerSecond:(CGFloat)pixelPerSecond {
    CGFloat oldPixelPerSecond = _pixelPerSecond;
    CGFloat newPixelPerSecond = std::fmax(pixelPerSecond, 30.);
    
    CGFloat oldContentOffsetX = self.collectionView.contentOffset.x;
    CGFloat estimatedNewContentOffsetX = oldContentOffsetX * (newPixelPerSecond / oldPixelPerSecond);
    CGFloat contentOffsetXDiff = estimatedNewContentOffsetX - oldContentOffsetX;
    
    _pixelPerSecond = newPixelPerSecond;
    
    UICollectionViewLayoutInvalidationContext *invalidationContext = [UICollectionViewLayoutInvalidationContext new];
    invalidationContext.contentOffsetAdjustment = CGPointMake(contentOffsetXDiff,
                                                              0.);
    
    [self invalidateLayoutWithContext:invalidationContext];
    [invalidationContext release];
}

- (void)commonInit_EditorTrackCollectionViewLayout __attribute__((objc_direct)) {
    _pixelPerSecond = 30.f;
    [self registerClass:EditorTrackPlayHeadCollectionReusableView.class forDecorationViewOfKind:EditorTrackPlayHeadCollectionReusableView.elementKind];
    [self registerClass:EditorTrackThumbnailPlayerCollectionReusableView.class forDecorationViewOfKind:EditorTrackThumbnailPlayerCollectionReusableView.elementKind];
}

- (NSDictionary<NSString *, id> *)videoTrackLayoutInfoWithSectionModel:(EditorTrackSectionModel *)sectionModel 
                                                          sectionIndex:(NSInteger)sectionIndex
                                                               yOffset:(CGFloat)yOffset
                                                              delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    CGFloat xOffset = self.collectionView.bounds.size.width * 0.5f;
    NSMutableArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
    
    std::vector<NSInteger> itemIndexes(numberOfItems);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [sectionIndex, delegate, &xOffset, yOffset, layoutAttributesArray, self](const NSInteger itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = itemModel.compositionTrackSegment;
        
        CMTime time = trackSegment.timeMapping.target.duration;
        CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        EditorTrackCollectionViewLayoutAttributes *layoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xOffset,
                                            yOffset + 10.f,
                                            width,
                                            70.f);
        
        xOffset += width;
        
        [layoutAttributesArray addObject:layoutAttributes];
    });
    
    NSDictionary<NSString *, id> *results = @{
        LAYOUT_ATTRIBUTES_ARRAY_KEY: layoutAttributesArray,
        TOTAL_WIDTH_KEY: @(xOffset + self.collectionView.bounds.size.width * 0.5f),
        Y_OFFSET: @(yOffset + 10.f + 70.f)
    };
    
    [layoutAttributesArray release];
    
    return results;
}

- (NSDictionary<NSIndexPath *, EditorTrackCollectionViewLayoutAttributes *> *)videoTrackSegmentThumbnailLayoutAttributesByIndexPathFromVideoTrackLayoutAttributesArray:(NSArray<EditorTrackCollectionViewLayoutAttributes *> *)videoTrackLayoutAttributesArray __attribute__((objc_direct)) {
    NSMutableDictionary<NSIndexPath *, EditorTrackCollectionViewLayoutAttributes *> *results = [NSMutableDictionary new];
    
    for (EditorTrackCollectionViewLayoutAttributes *videoTrackLayoutAttributes in videoTrackLayoutAttributesArray) {
        CGRect cellFrame = videoTrackLayoutAttributes.frame;
        
        CGFloat cellWidth = CGRectGetWidth(cellFrame);
        if (cellWidth <= 0.) continue;
        
        CGFloat cellHeight = CGRectGetHeight(cellFrame);
        if (cellHeight <= 0.) continue;
        
        NSUInteger thumbnailsCount = static_cast<NSUInteger>(std::ceil(cellWidth / cellHeight));
        if (thumbnailsCount == 0) continue;
        
        CGFloat thumbnailWidth = cellWidth / static_cast<CGFloat>(thumbnailsCount);
        CGFloat cellX = CGRectGetMinX(cellFrame);
        CGFloat cellY = CGRectGetMinY(cellFrame);
        
        NSInteger sectionIndex = videoTrackLayoutAttributes.indexPath.section;
        NSIndexPath *cellIndexPath = videoTrackLayoutAttributes.indexPath;
        
        for (NSUInteger i = 0; i < thumbnailsCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:results.count + 1 /* TODO - playhead */ inSection:sectionIndex];
            
            EditorTrackCollectionViewLayoutAttributes *videoTrackSegmentThumbnailLayoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:EditorTrackThumbnailPlayerCollectionReusableView.elementKind withIndexPath:indexPath];
            
            __weak auto weakSelf = self;
            
            videoTrackSegmentThumbnailLayoutAttributes.assetResolver = ^AVAsset * _Nullable{
                auto unwrappedSelf = weakSelf;
                if (unwrappedSelf == nil) return nil;
                
                auto delegate = unwrappedSelf.delegate;
                if (delegate == nil) return nil;
                
                EditorTrackSectionModel *sectionModel = [delegate editorTrackCollectionViewLayout:unwrappedSelf sectionModelForIndex:sectionIndex];
                if (sectionModel == nil) return nil;
                
                return sectionModel.composition;
            };
            
            Float64 timeMultiplier = (Float64)i / (Float64)thumbnailsCount;
            
            videoTrackSegmentThumbnailLayoutAttributes.timeResolver = ^CMTime{
                auto unwrappedSelf = weakSelf;
                if (unwrappedSelf == nil) return kCMTimeInvalid;
                
                auto delegate = unwrappedSelf.delegate;
                if (delegate == nil) return kCMTimeInvalid;
                
                EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:unwrappedSelf itemModelForIndexPath:cellIndexPath];
                
                AVCompositionTrackSegment *trackSegment = itemModel.compositionTrackSegment;
                
                if (trackSegment == nil) return kCMTimeInvalid;
                
                CMTimeRange targetTimeRange = trackSegment.timeMapping.target;
                return CMTimeAdd(targetTimeRange.start, CMTimeMultiplyByFloat64(targetTimeRange.duration, timeMultiplier));
            };
            
            videoTrackSegmentThumbnailLayoutAttributes.zIndex = -1;
            videoTrackSegmentThumbnailLayoutAttributes.frame = CGRectMake(cellX + thumbnailWidth * static_cast<CGFloat>(i),
                                                                          cellY,
                                                                          thumbnailWidth,
                                                                          cellHeight);
            
            results[indexPath] = videoTrackSegmentThumbnailLayoutAttributes;
        }
    }
    
    return [results autorelease];
}

- (NSDictionary<NSString *, id> *)audioTrackLayoutInfoWithSectionModel:(EditorTrackSectionModel *)sectionModel
                                                          sectionIndex:(NSInteger)sectionIndex
                                                               yOffset:(CGFloat)yOffset
                                                              delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    CGFloat xOffset = self.collectionView.bounds.size.width * 0.5f;
    NSMutableArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
    
    std::vector<NSInteger> itemIndexes(numberOfItems);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = itemModel.compositionTrackSegment;
        
        CMTime time = trackSegment.timeMapping.target.duration;
        CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        EditorTrackCollectionViewLayoutAttributes *layoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xOffset,
                                            yOffset + 10.f,
                                            width,
                                            50.f);
        
        xOffset += width;
        
        [layoutAttributesArray addObject:layoutAttributes];
    };
    
    NSDictionary<NSString *, id> *results = @{
        LAYOUT_ATTRIBUTES_ARRAY_KEY: layoutAttributesArray,
        TOTAL_WIDTH_KEY: @(xOffset + self.collectionView.bounds.size.width * 0.5f),
        Y_OFFSET: @(yOffset + 10.f + 50.f)
    };
    
    [layoutAttributesArray release];
    
    return results;
}

- (NSDictionary<NSString *, id> *)captionTrackLayoutInfoWithSectionModel:(EditorTrackSectionModel *)sectionModel 
                                                            sectionIndex:(NSInteger)sectionIndex
                                                                 yOffset:(CGFloat)yOffset
                                                                delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    CGFloat xPadding = self.collectionView.bounds.size.width * 0.5f;
    CGFloat totalWidth = xPadding;
    NSMutableArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
    
    for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        SVEditorRenderCaption *renderCaption = itemModel.renderCaption;
        
        CGFloat xOffset = self.pixelPerSecond * ((CGFloat)renderCaption.startTime.value / (CGFloat)renderCaption.startTime.timescale);
        CMTime durationTime = CMTimeSubtract(renderCaption.endTime, renderCaption.startTime);
        CGFloat width = self.pixelPerSecond * ((CGFloat)durationTime.value / (CGFloat)durationTime.timescale);
        
        EditorTrackCollectionViewLayoutAttributes *layoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xPadding + xOffset,
                                            yOffset + 10.f,
                                            width,
                                            70.f);
        
        totalWidth += width;
        yOffset += 50.f + 10.f;
        
        [layoutAttributesArray addObject:layoutAttributes];
    };
    
    NSDictionary<NSString *, id> *results = @{
        LAYOUT_ATTRIBUTES_ARRAY_KEY: layoutAttributesArray,
        TOTAL_WIDTH_KEY: @(totalWidth + xPadding),
        Y_OFFSET: @(yOffset)
    };
    
    [layoutAttributesArray release];
    
    return results;
}

- (EditorTrackCollectionViewLayoutAttributes *)playHeadDecorationLayoutAttributes {
    EditorTrackCollectionViewLayoutAttributes *decorationLayoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:EditorTrackPlayHeadCollectionReusableView.elementKind withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    
    CGRect collectionViewBounds = self.collectionView.bounds;
    decorationLayoutAttributes.frame = CGRectMake(CGRectGetMidX(collectionViewBounds) - 1.,
                                                  0.,
                                                  2.,
                                                  CGRectGetHeight(collectionViewBounds));
    decorationLayoutAttributes.zIndex = 1;
    
    return decorationLayoutAttributes;
}

@end
