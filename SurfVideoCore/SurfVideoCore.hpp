//
//  SurfVideoCore.h
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 5/9/24.
//

#import <Foundation/Foundation.h>

//! Project version number for SurfVideoCore.
FOUNDATION_EXPORT double SurfVideoCoreVersionNumber;

//! Project version string for SurfVideoCore.
FOUNDATION_EXPORT const unsigned char SurfVideoCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SurfVideoCore/PublicHeader.h>

#import <SurfVideoCore/constants.hpp>
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/SVVideoProject.hpp>
#import <SurfVideoCore/SVVideoTrack.hpp>
#import <SurfVideoCore/SVAudioTrack.hpp>
#import <SurfVideoCore/SVCaptionTrack.hpp>
#import <SurfVideoCore/SVTrack.hpp>
#import <SurfVideoCore/SVVideoClip.hpp>
#import <SurfVideoCore/SVAudioClip.hpp>
#import <SurfVideoCore/SVClip.hpp>
#import <SurfVideoCore/SVCaption.hpp>
#import <SurfVideoCore/SVPHAssetFootage.hpp>
#import <SurfVideoCore/SVLocalFileFootage.hpp>
#import <SurfVideoCore/SVFootage.hpp>
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/NSManagedObjectModel+SVObjectModel.hpp>
#import <SurfVideoCore/SVKeyValueObservation.h>
#import <SurfVideoCore/NSObject+SVKeyValueObservation.h>
#import <SurfVideoCore/NSObject+Foundation_IvarDescription.h>
#import <SurfVideoCore/SVAudioSamplesExtractor.hpp>
#import <SurfVideoCore/SVAudioSamplesManager.hpp>
#import <SurfVideoCore/SVAudioSample.hpp>
#import <SurfVideoCore/SVAudioWaveformView.hpp>
#import <SurfVideoCore/SVRunLoop.hpp>
#import <SurfVideoCore/SVEditorRenderCaption.hpp>
#import <SurfVideoCore/SVEditorRenderElement.hpp>
#import <SurfVideoCore/SVEditorService.hpp>
#import <SurfVideoCore/SVEditorService+AudioClip.hpp>
#import <SurfVideoCore/SVEditorService+Caption.hpp>
#import <SurfVideoCore/SVEditorService+VideoClip.hpp>
#import <SurfVideoCore/SVImageUtils.hpp>
#import <SurfVideoCore/ProjectsViewModel.hpp>
#import <SurfVideoCore/PHPickerConfiguration+OnlyReturnsIdentifiers.hpp>
