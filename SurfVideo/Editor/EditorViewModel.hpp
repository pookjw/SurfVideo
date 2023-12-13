//
//  EditorViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import <memory>
#import <variant>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

class EditorViewModel {
public:
    static CMPersistentTrackID mainVideoTrack() { return 1 << 0; };
    
    EditorViewModel(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> videoProjectVariant);
    ~EditorViewModel();
    EditorViewModel(const EditorViewModel&) = delete;
    EditorViewModel& operator=(const EditorViewModel&) = delete;
    
    void initialize(std::shared_ptr<EditorViewModel> ref,
                    void (^progressHandler)(NSProgress *progress),
                    void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
    void appendVideosFromPickerResults(std::shared_ptr<EditorViewModel> ref,
                                       NSArray<PHPickerResult *> *pickerResults,
                                       void (^progressHandler)(NSProgress *progress),
                                       void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
private:
    dispatch_queue_t _queue;
    std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> _videoProjectVariant;
    AVComposition *_composition;
    
    void videoProjectFromVarient(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> initialData, void (^completionHandler)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error));
    void compositionFromVideoProject(SVVideoProject *videoProject, void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
    void appendVidoesFromVideoProject(std::shared_ptr<EditorViewModel> ref, 
                                      SVVideoProject *videoProject,
                                      AVComposition * _Nullable composition,
                                      void (^progressHandler)(NSProgress *progress),
                                      void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
    void appendVideosFromFetchResult(std::shared_ptr<EditorViewModel> ref,
                                     PHFetchResult<PHAsset *> *fetchResult,
                                     AVComposition * _Nullable composition,
                                     void (^progressHandler)(NSProgress *progress),
                                     void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
    void appendVideosFromAssetIdentifiers(std::shared_ptr<EditorViewModel> ref,
                                          NSArray<NSString *> *assetIdentifiers,
                                          AVComposition * _Nullable composition,
                                          void (^progressHandler)(NSProgress *progress),
                                          void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
    
    void appendVideosFromPickerResults(std::shared_ptr<EditorViewModel> ref,
                                       NSArray<PHPickerResult *> *pickerResults,
                                       AVComposition * _Nullable composition,
                                       void (^progressHandler)(NSProgress *progress),
                                       void (^completionHandler)(AVComposition * _Nullable composition, NSError * _Nullable error));
};

NS_ASSUME_NONNULL_END
