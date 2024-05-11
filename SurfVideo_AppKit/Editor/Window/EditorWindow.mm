//
//  EditorWindow.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorWindow.hpp"
#import "EditorViewController.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface EditorWindow () <NSToolbarDelegate>
@property (class, readonly, nonatomic) NSToolbarIdentifier toolbarIdentifier;
@property (class, readonly, nonatomic) NSToolbarIdentifier addVideoClipToolbarIdentifier;
@property (class, readonly, nonatomic) NSToolbarIdentifier addAudioClipToolbarIdentifier;
@property (class, readonly, nonatomic) NSToolbarIdentifier addCaptionToolbarIdentifier;
@property (class, readonly, nonatomic) NSToolbarIdentifier exportToolbarIdentifier;
@property (retain, readonly, nonatomic) SVVideoProject *videoProject;
@property (retain, readonly, nonatomic) EditorViewController *editorViewController;
@property (retain, readonly, nonatomic) NSToolbarItem *addVideoClipToolbarItem;
@property (retain, readonly, nonatomic) NSToolbarItem *addAudioClipToolbarItem;
@property (retain, readonly, nonatomic) NSToolbarItem *addCaptionToolbarItem;
@property (retain, readonly, nonatomic) NSToolbarItem *exportToolbarItem;
@end

@implementation EditorWindow

@synthesize addVideoClipToolbarItem = _addVideoClipToolbarItem;
@synthesize addAudioClipToolbarItem = _addAudioClipToolbarItem;
@synthesize addCaptionToolbarItem = _addCaptionToolbarItem;
@synthesize exportToolbarItem = _exportToolbarItem;

+ (NSToolbarIdentifier)toolbarIdentifier {
    return @"EditorWindow.toolbarIdentifier";
}

+ (NSToolbarIdentifier)addVideoClipToolbarIdentifier {
    return @"EditorWindow.addVideoClipToolbarIdentifier";
}

+ (NSToolbarIdentifier)addAudioClipToolbarIdentifier {
    return @"EditorWindow.addAudioClipToolbarIdentifier";
}

+ (NSToolbarIdentifier)addCaptionToolbarIdentifier {
    return @"EditorWindow.addCaptionToolbarIdentifier";
}

+ (NSToolbarIdentifier)exportToolbarIdentifier {
    return @"EditorWindow.exportToolbarIdentifier";
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    self = [self initWithContentRect:NSMakeRect(0., 0., 600., 400.)
                           styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskTitled
                             backing:NSBackingStoreBuffered
                               defer:YES];
    
    if (self) {
        self.title = @"Editor";
        self.contentMinSize = NSMakeSize(400., 400.);
        self.toolbar = [self makeToolbar];
        
        EditorViewController *editorViewController = [[EditorViewController alloc] initWithVideoProject:videoProject];
        self.contentViewController = editorViewController;
        _editorViewController = [editorViewController retain];
        [editorViewController release];
    }
    
    return self;
}

- (void)dealloc {
    [_videoProject release];
    [_editorViewController release];
    [_addVideoClipToolbarItem release];
    [_addAudioClipToolbarItem release];
    [_addCaptionToolbarItem release];
    [_exportToolbarItem release];
    [super dealloc];
}

- (NSToolbar *)makeToolbar __attribute__((objc_direct)) {
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:[EditorWindow toolbarIdentifier]];
    
    toolbar.delegate = self;
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    toolbar.allowsUserCustomization = NO;
    
    return [toolbar autorelease];
}

- (NSToolbarItem *)addVideoClipToolbarItem {
    if (auto addVideoClipToolbarItem = _addVideoClipToolbarItem) return addVideoClipToolbarItem;
    
    NSToolbarItem *addVideoClipToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[EditorWindow addVideoClipToolbarIdentifier]];
    addVideoClipToolbarItem.image = [NSImage imageWithSystemSymbolName:@"photo" accessibilityDescription:nil];
    addVideoClipToolbarItem.target = self;
    addVideoClipToolbarItem.action = @selector(addVideoClipToolbarItemDidTrigger:);
    
    _addVideoClipToolbarItem = [addVideoClipToolbarItem retain];
    return [addVideoClipToolbarItem autorelease];
}

- (NSToolbarItem *)addAudioClipToolbarItem {
    if (auto addAudioClipToolbarItem = _addAudioClipToolbarItem) return addAudioClipToolbarItem;
    
    NSToolbarItem *addAudioClipToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[EditorWindow addAudioClipToolbarIdentifier]];
    addAudioClipToolbarItem.image = [NSImage imageWithSystemSymbolName:@"music.note" accessibilityDescription:nil];
    addAudioClipToolbarItem.target = self;
    addAudioClipToolbarItem.action = @selector(addAudioClipToolbarItemDidTrigger:);
    
    _addAudioClipToolbarItem = [addAudioClipToolbarItem retain];
    return [addAudioClipToolbarItem autorelease];
}

- (NSToolbarItem *)addCaptionToolbarItem {
    if (auto addCaptionToolbarItem = _addCaptionToolbarItem) return addCaptionToolbarItem;
    
    NSToolbarItem *addCaptionToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[EditorWindow addCaptionToolbarIdentifier]];
    addCaptionToolbarItem.image = [NSImage imageWithSystemSymbolName:@"plus.bubble.fill" accessibilityDescription:nil];
    addCaptionToolbarItem.target = self;
    addCaptionToolbarItem.action = @selector(addCaptionToolbarItemDidTrigger:);
    
    _addCaptionToolbarItem = [addCaptionToolbarItem retain];
    return [addCaptionToolbarItem autorelease];
}

- (NSToolbarItem *)exportToolbarItem {
    if (auto exportToolbarItem = _exportToolbarItem) return exportToolbarItem;
    
    NSToolbarItem *exportToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[EditorWindow exportToolbarIdentifier]];
    exportToolbarItem.image = [NSImage imageWithSystemSymbolName:@"square.and.arrow.up" accessibilityDescription:nil];
    exportToolbarItem.target = self;
    exportToolbarItem.action = @selector(exportToolbarItemDidTrigger:);
    
    _exportToolbarItem = [exportToolbarItem retain];
    return [exportToolbarItem autorelease];
}

- (void)addVideoClipToolbarItemDidTrigger:(NSToolbarItem *)sender {
    
}

- (void)addAudioClipToolbarItemDidTrigger:(NSToolbarItem *)sender {
    
}

- (void)addCaptionToolbarItemDidTrigger:(NSToolbarItem *)sender {
    
}

- (void)exportToolbarItemDidTrigger:(NSToolbarItem *)sender {
    
}

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:[EditorWindow addVideoClipToolbarIdentifier]]) {
        return self.addVideoClipToolbarItem;
    } else if ([itemIdentifier isEqualToString:[EditorWindow addAudioClipToolbarIdentifier]]) {
        return self.addAudioClipToolbarItem;
    } else if ([itemIdentifier isEqualToString:[EditorWindow addCaptionToolbarIdentifier]]) {
        return self.addCaptionToolbarItem;
    } else if ([itemIdentifier isEqualToString:[EditorWindow exportToolbarIdentifier]]) {
        return self.exportToolbarItem;
    } else {
        return nil;
    }
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        [EditorWindow addVideoClipToolbarIdentifier],
        [EditorWindow addAudioClipToolbarIdentifier],
        [EditorWindow addCaptionToolbarIdentifier],
        NSToolbarSpaceItemIdentifier,
        [EditorWindow exportToolbarIdentifier]
    ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        [EditorWindow addVideoClipToolbarIdentifier],
        [EditorWindow addAudioClipToolbarIdentifier],
        [EditorWindow addCaptionToolbarIdentifier],
        NSToolbarSpaceItemIdentifier,
        [EditorWindow exportToolbarIdentifier]
    ];
}

@end
