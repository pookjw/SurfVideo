//
//  PHImageManager+RequestAVAssets.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/11/23.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface PHImageManager (RequestAVAssets)
- (NSProgress *)sv_requestAVAssetsForFetchResult:(PHFetchResult<PHAsset *> *)assets options:(PHVideoRequestOptions * _Nullable)options partialResultHandler:(void (^)(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset *asset, BOOL *stop, BOOL isEnd))partialResultHandler;
@end

NS_ASSUME_NONNULL_END
