//
//  EditorTrackMainVideoTrackContentView.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackMainVideoTrackContentView.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackMainVideoTrackContentView ()
@property (copy, nonatomic) EditorTrackMainVideoTrackContentConfiguration *contentConfiguration;
@property (retain, nonatomic) UILabel *testLabel;
@end

@implementation EditorTrackMainVideoTrackContentView

- (instancetype)initWithContentConfiguration:(EditorTrackMainVideoTrackContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        _contentConfiguration = [contentConfiguration copy];
        
        UILabel *testLabel = [[UILabel alloc] initWithFrame:self.bounds];
        testLabel.numberOfLines = 0;
        testLabel.backgroundColor = UIColor.systemPinkColor;
        testLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:testLabel];
        [NSLayoutConstraint activateConstraints:@[
            [testLabel.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor],
            [testLabel.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [testLabel.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [testLabel.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
        ]];
        self.testLabel = testLabel;
        [testLabel release];
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_testLabel release];
    [super dealloc];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = configuration;
}

- (void)setContentConfiguration:(EditorTrackMainVideoTrackContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    _testLabel.text = [NSString stringWithFormat:@"%@", contentConfiguration.itemModel.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]];
}

@end
