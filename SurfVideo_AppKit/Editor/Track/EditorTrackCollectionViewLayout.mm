//
//  EditorTrackCollectionViewLayout.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackCollectionViewLayoutAttributes.hpp"
#import "EditorTrackThumbnailPlayerView.hpp"
#import <AVFoundation/AVFoundation.h>

@interface EditorTrackCollectionViewLayout ()
@property (assign, nonatomic) NSSize collectionViewContentSize;
@property (assign, nonatomic) CGFloat currentClipViewWidth;
@property (retain, readonly, nonatomic, direct) NSMutableDictionary<NSNumber *, NSArray<EditorTrackCollectionViewLayoutAttributes *> *> *layoutAttributesArrayBySectionIndex;
@end

@implementation EditorTrackCollectionViewLayout

+ (Class)layoutAttributesClass {
    return [EditorTrackCollectionViewLayoutAttributes class];
}

- (instancetype)init {
    if (self = [super init]) {
        _layoutAttributesArrayBySectionIndex = [NSMutableDictionary new];
        _pixelPerSecond = 30.f;
    }
    
    return self;
}

- (void)dealloc {
    [_layoutAttributesArrayBySectionIndex release];
    [super dealloc];
}

- (NSArray<__kindof NSCollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(NSRect)rect {
    NSMutableArray<EditorTrackCollectionViewLayoutAttributes *> *results = [NSMutableArray array];
    NSMutableDictionary<NSNumber *, NSArray<EditorTrackCollectionViewLayoutAttributes *> *> *layoutAttributesArrayBySectionIndex = _layoutAttributesArrayBySectionIndex;
    
    for (NSArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray in layoutAttributesArrayBySectionIndex.allValues) {
        for (EditorTrackCollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray) {
            if (NSIntersectsRect(layoutAttributes.frame, rect)) {
                [results addObject:layoutAttributes];
            }
        }
    }
    
    return results;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary<NSNumber *, NSArray<EditorTrackCollectionViewLayoutAttributes *> *> *layoutAttributesArrayBySectionIndex = _layoutAttributesArrayBySectionIndex;
    
    NSArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = layoutAttributesArrayBySectionIndex[@(indexPath.section)];
    EditorTrackCollectionViewLayoutAttributes *layoutAttributes = layoutAttributesArray[indexPath.item];
    
    return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(NSRect)newBounds {
    return newBounds.size.width != self.currentClipViewWidth;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    NSMutableDictionary<NSNumber *, NSArray<EditorTrackCollectionViewLayoutAttributes *> *> *layoutAttributesArrayBySectionIndex = _layoutAttributesArrayBySectionIndex;
    
    [layoutAttributesArrayBySectionIndex removeAllObjects];
    
    auto delegate = self.delegate;
    if (delegate == nil) return;
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if ((numberOfSections == 0) || (numberOfSections == NSNotFound)) return;
    
    CGFloat clipViewWidth = self.collectionView.enclosingScrollView.contentView.bounds.size.width;
    CGFloat yOffset = 0.f;
    CGFloat maxWidth = 0.f;
    CGFloat pixelPerSecond = self.pixelPerSecond;
    
    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        EditorTrackSectionModel *sectionModel = [delegate editorTrackCollectionViewLayout:self sectionModelForIndex:sectionIndex];
        
        if (sectionModel == nil) continue;
        
        EditorTrackSectionModelType sectionType = sectionModel.type;
        
        if (sectionType == EditorTrackSectionModelTypeMainVideoTrack) {
            CGFloat totalWidth = 0.;
            
            NSArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = [self videoTrackLayoutAttributesArrayForSectionIndex:sectionIndex pixelPerSecond:pixelPerSecond yOffsetPtr:&yOffset totalWidthPtr:&totalWidth delegate:delegate];
            
            layoutAttributesArrayBySectionIndex[@(sectionIndex)] = layoutAttributesArray;
            
            maxWidth = MAX(maxWidth, totalWidth);
        } else {
            abort();
        }
    }
    
    NSSize collectionViewContentSize = NSMakeSize(maxWidth, yOffset);
    self.collectionViewContentSize = collectionViewContentSize;
    self.currentClipViewWidth = clipViewWidth;
}

- (NSArray<EditorTrackCollectionViewLayoutAttributes *> *)videoTrackLayoutAttributesArrayForSectionIndex:(NSInteger)sectionIndex 
                                                                                          pixelPerSecond:(CGFloat)pixelPerSecond
                                                                                              yOffsetPtr:(CGFloat *)yOffsetPtr
                                                                                           totalWidthPtr:(CGFloat *)totalWidthPtr
                                                                                                delegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate __attribute__((objc_direct)) {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
    
    if (numberOfItems == 0) {
        return @[];
    }
    
    CGFloat halfWidth = self.collectionView.enclosingScrollView.contentView.bounds.size.width * 0.5;
    CGFloat xOffset = halfWidth;
    
    NSMutableArray<EditorTrackCollectionViewLayoutAttributes *> *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
    
    for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        if (itemModel == nil) continue;
        
        AVCompositionTrackSegment *compositionTrackSegment = itemModel.compositionTrackSegment;
        CMTime time = compositionTrackSegment.timeMapping.target.duration;
        CGFloat width = pixelPerSecond * CMTimeGetSeconds(time);
        
        EditorTrackCollectionViewLayoutAttributes *layoutAttributes = [EditorTrackCollectionViewLayoutAttributes layoutAttributesForItemWithIndexPath:indexPath];
        
        layoutAttributes.frame = NSMakeRect(xOffset,
                                            *yOffsetPtr,
                                            width,
                                            50.);
        
        xOffset += width;
        
        [layoutAttributesArray addObject:layoutAttributes];
    }
    
    *totalWidthPtr = xOffset + halfWidth;
    *yOffsetPtr += 50.;
    
    return [layoutAttributesArray autorelease];
}

- (CGFloat)contentOffsetXFromTime:(CMTime)time {
    return self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
}

- (CMTime)timeFromContentOffsetX:(CGFloat)contentOffsetX {
    std::int32_t timescale = 1000000L;
    CGFloat width = self.collectionViewContentSize.width - self.collectionView.enclosingScrollView.contentView.bounds.size.width;
    CGFloat trimmedOffsetX = MIN(MAX(0., contentOffsetX), width);
    
    return CMTimeMake((trimmedOffsetX / self.pixelPerSecond) * timescale, timescale);
}

@end
