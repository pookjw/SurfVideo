//
//  constants.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#ifndef constants_hpp
#define constants_hpp

#import <Foundation/Foundation.h>

extern NSErrorDomain const SurfVideoErrorDomain;

typedef NS_ERROR_ENUM(SurfVideoErrorDomain, SurfVideoErrorCode) {
    SurfVideoUserCancelledError,
    SurfVideoAlreadyInitializedError,
    SurfVideoNotInitializedError,
    SurfVideoNoURIRepresentationError,
    SurfVideoNoManagedObjectContextError,
    SurfVideoNoPhotoPermissionError,
    SurfVideoNoModelFoundError,
    SurfVideoNoTrackFoundError,
    SurfVideoUnknownTrackID,
    SurfVideoAssetNotFound,
    SurfVideoNotAudioTrack,
    SurfVideoNoFormatDescription,
    SurfVideNoAudioTrack,
    SurfVideoNoHashValue
};

extern NSString * const kEditorWindowSceneUserActivityType;
extern NSString * const EditorWindowUserActivityVideoProjectURIRepresentationKey;

#endif /* constants_hpp */
