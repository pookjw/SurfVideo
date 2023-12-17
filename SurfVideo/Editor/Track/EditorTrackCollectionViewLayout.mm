//
//  EditorTrackCollectionViewLayout.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackCollectionViewLayout.hpp"
#import <AVFoundation/AVFoundation.h>
#import <vector>
#import <numeric>

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout ()
@property (copy, nonatomic) NSDictionary<NSNumber *, NSSet<UICollectionViewLayoutAttributes *> *> * _Nullable allCachedAttributesForSection;
@property (copy, nonatomic) NSOrderedSet<UICollectionViewLayoutAttributes *> * _Nullable allCachedAttributes;
@property (assign, nonatomic) CGSize cachedContentSize;
@end

@implementation EditorTrackCollectionViewLayout

- (void)dealloc {
    [_allCachedAttributesForSection release];
    [_allCachedAttributes release];
    [super dealloc];
}

+ (Class)layoutAttributesClass {
    return UICollectionViewLayoutAttributes.class;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    UICollectionView *collectionView = self.collectionView;
    id<EditorTrackCollectionViewLayoutDelegate> delegate = self.delegate;
    NSInteger numberOfSections = collectionView.numberOfSections;
    
    if (collectionView == nil || numberOfSections == 0 || delegate == nil) {
        self.allCachedAttributesForSection = nil;
        return;
    }
    
    //
    
    std::vector<NSInteger> sectionIndexes(numberOfSections);
    std::iota(sectionIndexes.begin(), sectionIndexes.end(), 0);
    auto allCachedAttributesForSection = [NSMutableDictionary<NSNumber *, NSSet<UICollectionViewLayoutAttributes *> *> new];
    auto allCachedAttributes = [NSMutableOrderedSet<UICollectionViewLayoutAttributes *> new];
    
    CGSize cachedContentSize = std::accumulate(sectionIndexes.cbegin(),
                                               sectionIndexes.cend(),
                                               CGSizeZero,
                                               [self, collectionView, delegate, allCachedAttributesForSection, allCachedAttributes](CGSize partialSize, NSInteger sectionIndex) {
        NSInteger numberOfItems = [collectionView numberOfItemsInSection:sectionIndex];
        
        if (numberOfItems == 0) {
            return partialSize;
        }
        
        std::vector<NSInteger> itemIndexes(numberOfItems);
        std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
        
        const CGFloat y = partialSize.height;
        const CGFloat height = 100.f;
        
        auto cachedAttributes = [NSMutableSet<UICollectionViewLayoutAttributes *> new];
        
        CGFloat width = std::accumulate(itemIndexes.cbegin(),
                                        itemIndexes.cend(),
                                        0.f,
                                        [self, delegate, sectionIndex, allCachedAttributes, cachedAttributes, y, height](CGFloat partialWidth, NSInteger itemIndex) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            EditorTrackItemModel * _Nullable itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
            
            if (itemModel == nil) {
                return partialWidth;
            }
            
            AVCompositionTrackSegment *trackSegment = itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey];
            CMTimeMapping timeMapping = trackSegment.timeMapping;
            CMTime seconds = CMTimeConvertScale(timeMapping.target.duration, 80, kCMTimeRoundingMethod_Default); // 1sec = 80px
            CGFloat width = static_cast<CGFloat>(seconds.value);
            
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            layoutAttributes.indexPath = indexPath;
            layoutAttributes.frame = CGRectMake(partialWidth, y, width, height);
            
            [cachedAttributes addObject:layoutAttributes];
            [allCachedAttributes addObject:layoutAttributes];
            
            return partialWidth + width;
        });
        
        auto copiedCachedAttributes = static_cast<NSSet<UICollectionViewLayoutAttributes *> *>([cachedAttributes copy]);
        [cachedAttributes release];
        allCachedAttributesForSection[@(sectionIndex)] = copiedCachedAttributes;
        [copiedCachedAttributes release];
        
        return CGSizeMake(partialSize.width + width, partialSize.height + height);
    });
    
    self.allCachedAttributesForSection = allCachedAttributesForSection;
    [allCachedAttributesForSection release];
    self.allCachedAttributes = allCachedAttributes;
    [allCachedAttributes release];
    
    self.cachedContentSize = cachedContentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    UICollectionView *collectionView = self.collectionView;
    if (collectionView == nil) {
        return NO;
    }
    
    return CGRectEqualToRect(collectionView.bounds, newBounds);
}

- (CGSize)collectionViewContentSize {
    return _cachedContentSize;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSUInteger count = _allCachedAttributes.count;
    NSInteger firstMatchIndex = [self binSearchFromRect:rect startIndex:0 endIndex:count - 1];
    
    if (firstMatchIndex == NSNotFound) {
        return nil;
    }
    
    auto results = [NSMutableArray<UICollectionViewLayoutAttributes *> new];
    
    if (firstMatchIndex > 0) {
        NSIndexSet *firstIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, firstMatchIndex)];
        
        for (UICollectionViewLayoutAttributes *layoutAttributes in [_allCachedAttributes objectsAtIndexes:firstIndexSet].reverseObjectEnumerator) {
            CGRect layoutAttributesFrame = layoutAttributes.frame;
            if ((CGRectGetMaxY(layoutAttributesFrame) >= CGRectGetMinY(rect)) && (CGRectGetMaxX(layoutAttributesFrame) >= CGRectGetMinX(rect))) {
                [results addObject:layoutAttributes];
            } else {
                break;
            }
        }
    }
    
    NSIndexSet *secondIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstMatchIndex, count - firstMatchIndex)];
    for (UICollectionViewLayoutAttributes *layoutAttributes in [_allCachedAttributes objectsAtIndexes:secondIndexSet]) {
        CGRect layoutAttributesFrame = layoutAttributes.frame;
        if ((CGRectGetMinY(layoutAttributesFrame) <= CGRectGetMaxY(rect)) && (CGRectGetMinX(layoutAttributesFrame) <= CGRectGetMaxX(rect))) {
            [results addObject:layoutAttributes];
        } else {
            break;
        }
    }
    
    auto copy = static_cast<NSArray<UICollectionViewLayoutAttributes *> *>([results copy]);
    [results release];
    return [copy autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    auto cachedAttributes = _allCachedAttributesForSection[@(indexPath.section)];
    
    if (cachedAttributes == nil) {
        return nil;
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in cachedAttributes) {
        if ([layoutAttributes.indexPath isEqual:indexPath]) {
            return layoutAttributes;
        }
    }
    
    return nil;
}

- (NSInteger)binSearchFromRect:(CGRect)rect startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex __attribute__((objc_direct)) {
    if (endIndex < startIndex) {
        return NSNotFound;
    }
    
    const NSInteger midIndex = (startIndex + endIndex) / 2;
    UICollectionViewLayoutAttributes *layoutAttributes = _allCachedAttributes[midIndex];
    const CGRect layoutAttributesFrame = layoutAttributes.frame;
    
    if (CGRectIntersectsRect(layoutAttributesFrame, rect)) {
        return midIndex;
    } else {
        if ((CGRectGetMaxY(layoutAttributesFrame) < CGRectGetMinY(rect)) || (CGRectGetMaxX(layoutAttributesFrame) < CGRectGetMinX(rect))) {
            return [self binSearchFromRect:rect startIndex:(midIndex + 1) endIndex:endIndex];
        } else {
            return [self binSearchFromRect:rect startIndex:startIndex endIndex:(midIndex - 1)];
        }
    }
}

@end
