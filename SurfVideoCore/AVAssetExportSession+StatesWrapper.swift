//
//  AVAssetExportSession+StatesWrapper.swift
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/11/24.
//

@preconcurrency import AVFoundation

extension AVAssetExportSession {
    @objc public nonisolated func statesProgress(updateInterval: TimeInterval, progressHandler: @escaping @Sendable (_ session: AVAssetExportSession, _ progress: Progress) -> Void) {
        Task {
            for await result in states(updateInterval: updateInterval) {
                switch result {
                case .pending, .waiting:
                    break
                case .exporting(let progress):
                    progressHandler(self, progress)
                @unknown default:
                    fatalError()
                }
            }
        }
    }
}
