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
#define TOTAL_WIDTH @"totalWidth"
#define PIXEL_PER_SECOND 30.f
#define CENTER_LINE_ELEMENT_KIND @"EditorTrackCenterLineCollectionReusableView"

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout ()
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
        
        NSDictionary<NSString *, id> *layoutItemsDic = [self layoutItemsForSectionIndex:sectionIndex];
        NSArray<NSCollectionLayoutItem *> *layoutItems = layoutItemsDic[LAYOUT_ITEMS_KEY];
        CGFloat totalWidth = static_cast<NSNumber *>(layoutItemsDic[TOTAL_WIDTH]).floatValue;
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:totalWidth]
                                                                           heightDimension:[NSCollectionLayoutDimension absoluteDimension:100.f]];
        
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:layoutItems];
        
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

- (void)commonInit_EditorTrackCollectionViewLayout __attribute__((objc_direct)) {
    [self registerClass:EditorTrackCenterLineCollectionReusableView.class forDecorationViewOfKind:CENTER_LINE_ELEMENT_KIND];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

// TODO: Window 크기 바꾸면 작동 안함
- (CGPoint)contentOffsetFromTime:(CMTime)time {
    return CGPointMake(PIXEL_PER_SECOND * ((CGFloat)time.value / (CGFloat)time.timescale), 0.f);
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
        CGFloat width = PIXEL_PER_SECOND * ((CGFloat)time.value / (CGFloat)time.timescale);
        
        totalWidth += width;
        
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                                                          heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
        
//        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize
//                                                               supplementaryItems:@[]];
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithSize:itemSize decorationItems:@[[self centerLineDecorationItem]]];
        
        [items addObject:item];
    });
    
    NSDictionary<NSString *, id> *result = @{
        LAYOUT_ITEMS_KEY: items,
        TOTAL_WIDTH: @(totalWidth)
    };
    
    [items release];
    
    return result;
}

- (NSCollectionLayoutDecorationItem *)centerLineDecorationItem __attribute__((objc_direct)) {
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f]
                                                                  heightDimension:[NSCollectionLayoutDimension absoluteDimension:2.f]];
    
    NSCollectionLayoutAnchor *containerAnchor = [NSCollectionLayoutAnchor layoutAnchorWithEdges:NSDirectionalRectEdgeTop];
//    
//    NSCollectionLayoutDecorationItem *centerLineDecorationItem = [[NSCollectionLayoutDecorationItem alloc] initWithElementKind:CENTER_LINE_ELEMENT_KIND
//                                                                                                                          size:size
//                                                                                                                 contentInsets:NSDirectionalEdgeInsetsZero
//                                                                                                               containerAnchor:containerAnchor
//                                                                                                                    itemAnchor:containerAnchor
//                                                                                                                        zIndex:100
//                                                                                                         registrationViewClass:EditorTrackCenterLineCollectionReusableView.class
//                                                                                                        isBackgroundDecoration:YES];
//    
//    return centerLineDecorationItem;
//    return [NSCollectionLayoutDecorationItem backgroundDecorationItemWithElementKind:CENTER_LINE_ELEMENT_KIND];
    auto result = [NSCollectionLayoutDecorationItem decorationItemWithSize:size elementKind:CENTER_LINE_ELEMENT_KIND containerAnchor:containerAnchor];
    result.isBackgroundDecoration = NO;
    result.zIndex = 100;
//    result._registrationViewClass = EditorTrackCenterLineCollectionReusableView.class;
    return result;
}

@end
