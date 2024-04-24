//
//  EditorTrackCollectionViewLayout.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/22/24.
//

#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackCenterLineCollectionReusableView.hpp"
#import <AVFoundation/AVFoundation.h>
#import <vector>
#import <numeric>

#define LAYOUT_ATTRIBUTES_ARRAY_KEY @"layoutAttributesArray"
#define TOTAL_WIDTH_KEY @"totalWidth"
#define Y_OFFSET @"yOffset"
#define CENTER_LINE_ELEMENT_KIND @"EditorTrackCenterLineCollectionReusableView"

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout () {
    CGSize _collectionViewContentSize;
}
@property (copy, nonatomic) NSArray<UICollectionViewLayoutAttributes *> * _Nullable mainVideoTrackLayoutAttributesArray;
@property (copy, nonatomic) NSArray<UICollectionViewLayoutAttributes *> * _Nullable audioTrackLayoutAttributesArray;
@property (copy, nonatomic) NSArray<UICollectionViewLayoutAttributes *> * _Nullable captionTrackLayoutAttributesArray;
@property (readonly, nonatomic) UICollectionViewLayoutAttributes *centerLineDecorationLayoutAttributes;
@end

@implementation EditorTrackCollectionViewLayout

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
    [super dealloc];
}

- (CGSize)collectionViewContentSize {
    return _collectionViewContentSize;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    self.mainVideoTrackLayoutAttributesArray = nil;
    self.captionTrackLayoutAttributesArray = nil;
    
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
                
                self.mainVideoTrackLayoutAttributesArray = result[LAYOUT_ATTRIBUTES_ARRAY_KEY];
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
    
    _collectionViewContentSize = CGSizeMake(maxWidth, yOffset);
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
    return [[[self.mainVideoTrackLayoutAttributesArray arrayByAddingObjectsFromArray:self.captionTrackLayoutAttributesArray] arrayByAddingObject:self.centerLineDecorationLayoutAttributes] arrayByAddingObjectsFromArray:self.audioTrackLayoutAttributesArray];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:CENTER_LINE_ELEMENT_KIND]) {
        return self.centerLineDecorationLayoutAttributes;
    } else {
        return nil;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    UICollectionViewLayoutInvalidationContext *result = [UICollectionViewLayoutInvalidationContext new];
    
    [result invalidateDecorationElementsOfKind:CENTER_LINE_ELEMENT_KIND atIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    return [result autorelease];
}

- (CGPoint)contentOffsetFromTime:(CMTime)time {
    return CGPointMake(self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale), 0.f);
}

- (CMTime)timeFromContentOffset:(CGPoint)contentOffset {
    std::int32_t timescale = 1000000L;
    return CMTimeMake((contentOffset.x / self.pixelPerSecond) * timescale, timescale);
}

- (void)setPixelPerSecond:(CGFloat)pixelPerSecond {
    _pixelPerSecond = std::fmin(std::fmax(pixelPerSecond, 30.), 100.);
    [self invalidateLayout];
}

- (void)commonInit_EditorTrackCollectionViewLayout __attribute__((objc_direct)) {
    _pixelPerSecond = 30.f;
    [self registerClass:EditorTrackCenterLineCollectionReusableView.class forDecorationViewOfKind:CENTER_LINE_ELEMENT_KIND];
}

- (NSDictionary<NSString *, id> *)videoTrackLayoutInfoWithSectionModel:(EditorTrackSectionModel *)sectionModel 
                                                          sectionIndex:(NSInteger)sectionIndex
                                                               yOffset:(CGFloat)yOffset
                                                              delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    CGFloat xOffset = self.collectionView.bounds.size.width * 0.5f;
    auto layoutAttributesArray = [[NSMutableArray<UICollectionViewLayoutAttributes *> alloc] initWithCapacity:numberOfItems];
    
    std::vector<NSInteger> itemIndexes(numberOfItems);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [sectionIndex, delegate, &xOffset, yOffset, layoutAttributesArray, self](const NSInteger itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = static_cast<AVAssetTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        
        CMTime time = trackSegment.timeMapping.target.duration;
        CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xOffset,
                                            yOffset + 10.f,
                                            width,
                                            100.f);
        
        xOffset += width;
        
        [layoutAttributesArray addObject:layoutAttributes];
    });
    
    NSDictionary<NSString *, id> *results = @{
        LAYOUT_ATTRIBUTES_ARRAY_KEY: layoutAttributesArray,
        TOTAL_WIDTH_KEY: @(xOffset + self.collectionView.bounds.size.width * 0.5f),
        Y_OFFSET: @(yOffset + 10.f + 100.f)
    };
    
    [layoutAttributesArray release];
    
    return results;
}

- (NSDictionary<NSString *, id> *)audioTrackLayoutInfoWithSectionModel:(EditorTrackSectionModel *)sectionModel
                                                          sectionIndex:(NSInteger)sectionIndex
                                                               yOffset:(CGFloat)yOffset
                                                              delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    CGFloat xOffset = self.collectionView.bounds.size.width * 0.5f;
    auto layoutAttributesArray = [[NSMutableArray<UICollectionViewLayoutAttributes *> alloc] initWithCapacity:numberOfItems];
    
    std::vector<NSInteger> itemIndexes(numberOfItems);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [sectionIndex, delegate, &xOffset, yOffset, layoutAttributesArray, self](const NSInteger itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = static_cast<AVAssetTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        
        CMTime time = trackSegment.timeMapping.target.duration;
        CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xOffset,
                                            yOffset + 10.f,
                                            width,
                                            50.f);
        
        xOffset += width;
        
        [layoutAttributesArray addObject:layoutAttributes];
    });
    
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
    auto layoutAttributesArray = [[NSMutableArray<UICollectionViewLayoutAttributes *> alloc] initWithCapacity:numberOfItems];
    
    std::vector<NSInteger> itemIndexes(numberOfItems);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [sectionIndex, delegate, xPadding, &yOffset, &totalWidth, layoutAttributesArray, self](const NSInteger itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto renderCaption = static_cast<EditorRenderCaption *>(itemModel.userInfo[EditorTrackItemModelRenderCaptionKey]);
        
        CGFloat xOffset = self.pixelPerSecond * ((CGFloat)renderCaption.startTime.value / (CGFloat)renderCaption.startTime.timescale);
        CMTime durationTime = CMTimeSubtract(renderCaption.endTime, renderCaption.startTime);
        CGFloat width = self.pixelPerSecond * ((CGFloat)durationTime.value / (CGFloat)durationTime.timescale);
        
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = CGRectMake(xPadding + xOffset,
                                            yOffset + 10.f,
                                            width,
                                            50.f);
        
        totalWidth += width;
        yOffset += 50.f + 10.f;
        
        [layoutAttributesArray addObject:layoutAttributes];
    });
    
    NSDictionary<NSString *, id> *results = @{
        LAYOUT_ATTRIBUTES_ARRAY_KEY: layoutAttributesArray,
        TOTAL_WIDTH_KEY: @(totalWidth + xPadding),
        Y_OFFSET: @(yOffset)
    };
    
    [layoutAttributesArray release];
    
    return results;
}

- (UICollectionViewLayoutAttributes *)centerLineDecorationLayoutAttributes {
    UICollectionViewLayoutAttributes *decorationLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:CENTER_LINE_ELEMENT_KIND withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    
    CGRect collectionViewBounds = self.collectionView.bounds;
    decorationLayoutAttributes.frame = CGRectMake(CGRectGetMidX(collectionViewBounds),
                                                  0.f,
                                                  2.f,
                                                  CGRectGetHeight(collectionViewBounds));
    decorationLayoutAttributes.zIndex = 1;
    
    return decorationLayoutAttributes;
}

@end
