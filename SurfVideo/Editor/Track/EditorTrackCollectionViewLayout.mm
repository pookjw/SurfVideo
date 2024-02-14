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
        
        NSUInteger itemCount = [_delegate editorTrackCollectionViewLayout:self numberOfItemsForSectionIndex:sectionIndex];
        auto items = [NSMutableArray<NSCollectionLayoutItem *> new];
        CGFloat totalWidth = 0.f;
        
        std::vector<NSUInteger> itemIndexes(itemCount);
        std::iota(itemIndexes.begin(), itemIndexes.end(), 0);
        std::for_each(itemIndexes.cbegin(), itemIndexes.cend(), [self, sectionIndex, _delegate, items, &totalWidth](auto itemIndex) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            
            EditorTrackItemModel *itemModel = [_delegate editorTrackCollectionViewLayout:self itemModelForIndexPath:indexPath];
            
            auto trackSegment = static_cast<AVAssetTrackSegment *>(itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
            
            CMTime time = CMTimeConvertScale(trackSegment.timeMapping.target.duration, 1, kCMTimeRoundingMethod_RoundAwayFromZero);
            
            CGFloat width = 30.f * time.value;
            
            totalWidth += width;
            
            NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                                                              heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
            
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize
                                                                   supplementaryItems:@[]];
            
            [items addObject:item];
        });
        
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:totalWidth]
                                                                           heightDimension:[NSCollectionLayoutDimension absoluteDimension:100.f]];
        
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:items];
        [items release];
        
        NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
        
        return section;
    } 
                            configuration:configuration];
    
    [configuration release];
    
    if (self) {
        
    }
    
    return self;
}

@end
