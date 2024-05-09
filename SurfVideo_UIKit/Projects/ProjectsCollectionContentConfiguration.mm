//
//  ProjectsCollectionContentConfiguration.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "ProjectsCollectionContentConfiguration.hpp"
#import "ProjectsCollectionContentView.hpp"

@implementation ProjectsCollectionContentConfiguration

- (instancetype)initWithVideoProjectObjectID:(NSManagedObjectID *)videoProjectObjectID {
    if (self = [self init]) {
        _videoProjectObjectID = [videoProjectObjectID copy];
    }
    
    return self;
}

- (void)dealloc {
    [_videoProjectObjectID release];
    [super dealloc];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView { 
    ProjectsCollectionContentView *contentView = [[ProjectsCollectionContentView alloc] initWithContentConfiguration:self];
    return [contentView autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state { 
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        if (![self.videoProjectObjectID isEqual:static_cast<decltype(self)>(other).videoProjectObjectID]) {
            return NO;
        }
        
        return YES;
    }
}

- (NSUInteger)hash {
    return self.videoProjectObjectID.hash;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    decltype(self) copy = [self.class new];
    
    if (copy) {
        copy->_videoProjectObjectID = [self.videoProjectObjectID copy];
    }
    
    return copy;
}

@end
