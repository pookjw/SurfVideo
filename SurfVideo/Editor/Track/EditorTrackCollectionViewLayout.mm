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

#define LAYOUT_ITEMS_KEY @"layoutItems"
#define TOTAL_WIDTH @"totalWidth"
#define PIXEL_PER_SECOND 30.f

__attribute__((objc_direct_members))
@interface EditorTrackCollectionViewLayout ()
@end

@implementation EditorTrackCollectionViewLayout

- (instancetype)initWithDelegate:(id<EditorTrackCollectionViewLayoutDelegate>)delegate {
    UICollectionViewCompositionalLayoutConfiguration *configuration = [UICollectionViewCompositionalLayoutConfiguration new];
    configuration.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
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
        section.contentInsets = NSDirectionalEdgeInsetsMake(0.f, inset, 0.f, inset);
        
        return section;
    } 
                            configuration:configuration];
    
    [configuration release];
    
    if (self) {
        _delegate = delegate;
    }
    
    return self;
}

// TODO: Window 크기 바꾸면 작동 안함
- (CGPoint)contentOffsetFromTime:(CMTime)time {
    CMTimeScale timescale = 1000000L;
    CMTime convertedTime = CMTimeConvertScale(time, timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    
    return CGPointMake(PIXEL_PER_SECOND * ((CGFloat)convertedTime.value / timescale), 0.f);
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
        
        CMTimeScale timescale = 1000000L;
        CMTime time = CMTimeConvertScale(trackSegment.timeMapping.target.duration, 1000000L, kCMTimeRoundingMethod_RoundAwayFromZero);
        
        CGFloat width = PIXEL_PER_SECOND * ((CGFloat)time.value / 1000000L);
        
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

@end
