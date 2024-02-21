//
//  EditorTrackCollectionViewLayout.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackCollectionViewLayout.hpp"
#import "NSCollectionLayoutDecorationItem+Private.h"
#import "EditorTrackCenterLineCollectionReusableView.hpp"
#import "NSCollectionLayoutSection+Private.h"
#import "NSCollectionLayoutItem+Private.h"
#import <AVFoundation/AVFoundation.h>
#import <vector>
#import <numeric>
#import <objc/message.h>

#define LAYOUT_ITEMS_KEY @"layoutItems"
#define GROUP_CUSTOM_ITEMS_KEY @"groupCustomItems"
#define TOTAL_WIDTH @"totalWidth"
#define CENTER_LINE_ELEMENT_KIND @"EditorTrackCenterLineCollectionReusableView"

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout ()
@property (readonly, nonatomic) UICollectionViewLayoutAttributes *centerLineDecorationLayoutAttributes;
@end

@implementation EditorTrackCollectionViewLayout

- (instancetype)initWithDelegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate {
    UICollectionViewCompositionalLayoutConfiguration *configuration = [UICollectionViewCompositionalLayoutConfiguration new];
    configuration.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    configuration.boundarySupplementaryItems = @[];
    
    self = [super initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        auto _delegate = delegate;
        if (_delegate == nil) {
            return nil;
        }
        
        NSDictionary<NSString *, id> *groupCustomItemsDic = [self groupCustomItemsForSectionIndex:sectionIndex];
        NSArray<NSCollectionLayoutGroupCustomItem *> *groupCustomItems = groupCustomItemsDic[GROUP_CUSTOM_ITEMS_KEY];
        CGFloat totalWidth = static_cast<NSNumber *>(groupCustomItemsDic[TOTAL_WIDTH]).floatValue;
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:totalWidth]
                                                                           heightDimension:[NSCollectionLayoutDimension absoluteDimension:100.f]];
        
//        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:layoutItems];
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup customGroupWithLayoutSize:groupSize itemProvider:^NSArray<NSCollectionLayoutGroupCustomItem *> * _Nonnull(id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
            return groupCustomItems;
        }];
        
        NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
        CGFloat inset = layoutEnvironment.container.effectiveContentSize.width * 0.5f;
        section._cornerRadius = 30.f;
        section.contentInsets = NSDirectionalEdgeInsetsMake(0.f, inset, 0.f, inset);
        
        return section;
    } 
                            configuration:configuration];
    
    [configuration release];
    
    if (self) {
        _delegate = delegate;
        [self commonInit_EditorTrackCollectionViewLayout];
    }
    
    return self;
}

- (void)setPixelPerSecond:(CGFloat)pixelPerSecond {
    _pixelPerSecond = std::fmaxf(pixelPerSecond, 30.f);
    [self invalidateLayout];
}

- (void)commonInit_EditorTrackCollectionViewLayout __attribute__((objc_direct)) {
    _pixelPerSecond = 30.f;
    [self registerClass:EditorTrackCenterLineCollectionReusableView.class forDecorationViewOfKind:CENTER_LINE_ELEMENT_KIND];
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    auto results = [super layoutAttributesForElementsInRect:rect];
    if (results.count == 0) return results;
    
    auto mutableResults = static_cast<NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *>([results mutableCopy]);
    
    [mutableResults addObject:self.centerLineDecorationLayoutAttributes];
    
    return [mutableResults autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if (auto result = [super layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath]) {
        return result;
    } else if ([elementKind isEqualToString:CENTER_LINE_ELEMENT_KIND]) {
        return self.centerLineDecorationLayoutAttributes;
    } else {
        return nil;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    auto result = [super invalidationContextForBoundsChange:newBounds];
    
    [result invalidateDecorationElementsOfKind:CENTER_LINE_ELEMENT_KIND atIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    return result;
}

- (CGPoint)contentOffsetFromTime:(CMTime)time {
    return CGPointMake(self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale), 0.f);
}

- (CMTime)timeFromContentOffset:(CGPoint)contentOffset {
    std::int32_t timescale = 1000000L;
    return CMTimeMake((contentOffset.x / self.pixelPerSecond) * timescale, timescale);
}

- (NSDictionary<NSString *, id> *)groupCustomItemsForSectionIndex:(NSInteger)sectionIndex __attribute__((objc_direct)) {
    auto delegate = self.delegate;
    NSUInteger itemCount = [delegate editorTrackCollectionViewLayout:self numberOfItemsForSectionIndex:sectionIndex];
    auto groupCustomItems = [NSMutableArray<NSCollectionLayoutGroupCustomItem *> new];
    CGFloat totalWidth = 0.f;
    
    std::vector<NSUInteger> itemIndexes(itemCount);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [self, delegate, sectionIndex, groupCustomItems, &totalWidth](auto itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = static_cast<AVAssetTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        
        if (trackSegment) {
            CMTime time = trackSegment.timeMapping.target.duration;
            CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
            
            CGRect frame = CGRectMake(totalWidth, 0.f, width, 100.f);
            NSCollectionLayoutGroupCustomItem *groupCustomItem = [NSCollectionLayoutGroupCustomItem customItemWithFrame:frame zIndex:0];
            
            totalWidth += width;
            
            [groupCustomItems addObject:groupCustomItem];
        } else {
            CGFloat width = 200.f;
            CGRect frame = CGRectMake(totalWidth, 100.f, width, 100.f);
            NSCollectionLayoutGroupCustomItem *groupCustomItem = [NSCollectionLayoutGroupCustomItem customItemWithFrame:frame zIndex:0];
            
            totalWidth += width;
            
            [groupCustomItems addObject:groupCustomItem];
        }
    });
    
    NSDictionary<NSString *, id> *result = @{
        GROUP_CUSTOM_ITEMS_KEY: groupCustomItems,
        TOTAL_WIDTH: @(totalWidth)
    };
    
    [groupCustomItems release];
    
    return result;
}

- (NSDictionary<NSString *, id> *)layoutItemsForSectionIndex:(NSInteger)sectionIndex __attribute__((objc_direct)) {
    auto delegate = self.delegate;
    NSUInteger itemCount = [delegate editorTrackCollectionViewLayout:self numberOfItemsForSectionIndex:sectionIndex];
    auto items = [NSMutableArray<NSCollectionLayoutItem *> new];
    CGFloat totalWidth = 0.f;
    
    std::vector<NSUInteger> itemIndexes(itemCount);
    std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
    
    std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [self, delegate, sectionIndex, items, &totalWidth](auto itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
        
        EditorTrackItemModel *itemModel = [delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
        
        auto trackSegment = static_cast<AVAssetTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
        
        CMTime time = trackSegment.timeMapping.target.duration;
        CGFloat width = self.pixelPerSecond * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        totalWidth += width;
        
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                                                          heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize
                                                               supplementaryItems:@[]];
        
        [items addObject:item];
    });
    
    NSDictionary<NSString *, id> *result = @{
        LAYOUT_ITEMS_KEY: items,
        TOTAL_WIDTH: @(totalWidth)
    };
    
    [items release];
    
    return result;
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
