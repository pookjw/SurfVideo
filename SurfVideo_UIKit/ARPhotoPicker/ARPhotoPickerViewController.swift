////
////  ARPhotoPickerViewController.swift
////  SurfVideo_UIKit
////
////  Created by Jinwoo Kim on 5/20/24.
////
//
//#if os(iOS) && !targetEnvironment(simulator)
//
//import UIKit
//import ARKit
//import RealityKit
//import Photos
//
//@MainActor
//final class ARPhotoPickerViewController: UIViewController {
//    private var arView: ARView! { view as? ARView }
//    @ViewLoading private var coachingOverlayView: ARCoachingOverlayView
//    @ViewLoading private var resetButton: UIButton
//    private var assetComponents: [AssetEntityComponent]?
//    private var resetTask: Task<Void, Never>?
//    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        commonInit()
//    }
//    
//    @available(*, unavailable)
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        commonInit()
//    }
//    
//    deinit {
//        resetTask?.cancel()
//    }
//    
//    override func loadView() {
//        view = ARView(
//            frame: .null,
//            cameraMode: .ar,
//            automaticallyConfigureSession: false
//        )
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let arView: ARView = self.arView
//        let session: ARSession = arView.session
//        
//        session.delegate = self
//        
//        let coachingOverlayView: ARCoachingOverlayView = .init(frame: arView.bounds)
//        coachingOverlayView.delegate = self
//        coachingOverlayView.goal = .anyPlane
//        coachingOverlayView.activatesAutomatically = true
//        coachingOverlayView.session = session
//        
//        coachingOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        arView.addSubview(coachingOverlayView)
//        self.coachingOverlayView = coachingOverlayView
//        
//        //
//        
//        let tapGesture: UITapGestureRecognizer = .init(target: self, action: #selector(tapGestureDidTrigger(_:)))
//        arView.addGestureRecognizer(tapGesture)
//        
//        //
//        
//        runConfiguration()
//    }
//    
//    private func commonInit() {
//        let navigationItem: UINavigationItem = navigationItem
//        
//        navigationItem.largeTitleDisplayMode = .never
//        
//        navigationItem.leadingItemGroups = [
//            .init(
//                barButtonItems: [
//                    .init(title: nil, image: .init(systemName: "arrow.clockwise"), target: self, action: #selector(resetBarButtonItemDidTrigger(_:)))
//                ], 
//                representativeItem: nil
//            )
//        ]
//    }
//    
//    @objc private func resetBarButtonItemDidTrigger(_ sender: UIBarButtonItem) {
//        reset()
//    }
//    
//    @objc private func tapGestureDidTrigger(_ sender: UITapGestureRecognizer) {
//        let arView: ARView = arView
//        let location: CGPoint = sender.location(in: arView)
//        
//        guard let entity: Entity = arView.entity(at: location),
//              let assetComponent: AssetEntityComponent = entity.components[AssetEntityComponent.self] as? AssetEntityComponent,
//              let asset: PHAsset = assetComponent.asset
//        else {
//            return
//        }
//        
//        print(asset)
//    }
//    
//    private func reset() {
//        resetTask?.cancel()
//        resetTask = .init {
//            let status: PHAuthorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
//            
//            guard status == .authorized || status == .limited else {
//                await view.window?.windowScene?.open(.init(string: UIApplication.openSettingsURLString)!, options: nil)
//                return
//            }
//            
//            let assetCollectionsFetchResult: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
//            
//            guard let recentlyAddedCollection: PHAssetCollection = assetCollectionsFetchResult.firstObject else {
//                return
//            }
//            
//            let fetchLimit: Int = 36
//            let fetchOptions: PHFetchOptions = .init()
//            fetchOptions.fetchLimit = fetchLimit
//            fetchOptions.sortDescriptors = [
//                .init(key: #keyPath(PHAsset.creationDate), ascending: false)
//            ]
//            
//            fetchOptions.includeHiddenAssets = false
//            
//            let assetsFetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: recentlyAddedCollection, options: fetchOptions)
//            
//            let imageRequestOptions: PHImageRequestOptions = .init()
//            imageRequestOptions.allowSecondaryDegradedImage = false
//            imageRequestOptions.deliveryMode = .opportunistic
//            imageRequestOptions.isNetworkAccessAllowed = true
//            
//            let stream = PHImageManager.default().requestImages(for: assetsFetchResult, targetSize: .init(width: 500.0, height: 500.0), contentMode: .aspectFit, options: imageRequestOptions)
//            var results: [Int: AssetEntityComponent] = [:]
//            
//            for await partial in stream {
//                let index: Int = partial.index
//                let asset: PHAsset = partial.asset
//                let result: Result<(image: UIImage, isDegraded: Bool), Error> = partial.result
//                
//                switch result {
//                case .success((let image, let isDegraged)):
//                    if !isDegraged {
//                        results[index] = .init(asset: asset, image: image)
//                    }
//                case .failure(let error):
//                    print(error)
//                }
//            }
//            
//            guard !Task.isCancelled else { 
//                return
//            }
//            
//            let assetComponents: [AssetEntityComponent] = .init(unsafeUninitializedCapacity: results.count) { buffer, initializedCount in
//                let count: Int = results.count
//                
//                guard count > .zero else { return }
//                
//                for (index, assetComponent) in results {
//                    (buffer.baseAddress! + index).initialize(to: assetComponent)
//                }
//                
//                initializedCount = results.count
//            }
//            
//            self.assetComponents = assetComponents
//            runConfiguration()
//        }
//    }
//    
//    private func runConfiguration(with session: ARSession? = nil) {
//        let configuration: ARWorldTrackingConfiguration = .init()
//        configuration.planeDetection = .horizontal
//        configuration.isCollaborationEnabled = true
//        (session ?? arView.session).run(configuration, options: [.removeExistingAnchors, .resetSceneReconstruction, .resetTracking, .stopTrackedRaycasts])
//    }
//    
//    private var assetModelEntities: [ModelEntity] {
//        return arView
//            .scene
//            .anchors
//            .filter({ $0.name == "ContainerAnchor" })
//            .compactMap({ $0 as? AnchorEntity })
//            .flatMap({ $0.children })
//            .filter({ $0.name == "ContainerEntity" })
//            .flatMap({ $0.children })
//            .compactMap({ $0 as? ModelEntity })
//    }
//}
//
//extension ARPhotoPickerViewController: ARSessionDelegate {
//    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        MainActor.assumeIsolated {
//            let assetModelEntities: [ModelEntity] = assetModelEntities
//            
//            if let assetComponents: [AssetEntityComponent],
//               !frame.anchors.contains(where: { $0.name == "ContainerAnchor" })
//            {
//                let arView: ARView = arView
//                let bounds: CGRect = arView.bounds
//                
//                guard let query: ARRaycastQuery = arView
//                    .makeRaycastQuery(from: CGPoint(x: bounds.midX, y: bounds.midY),
//                                      allowing: .estimatedPlane,
//                                      alignment: .any) else {
//                    return
//                }
//                
//                let raycasts: [ARRaycastResult] = session.raycast(query)
//                
//                guard let firstRaycast: ARRaycastResult = raycasts.first else { return }
//                
//                let anchor: ARAnchor = .init(name: "ContainerAnchor", transform: firstRaycast.worldTransform)
//                session.add(anchor: anchor)
//                
//                let anchorEntity: AnchorEntity = .init(anchor: anchor)
//                arView.scene.addAnchor(anchorEntity)
//                
//                let floorMeshPlane: MeshResource = .generatePlane(width: CellLayout.containerSize, depth: CellLayout.containerSize)
//                
//                let floorEntity: ModelEntity = .init(
//                    mesh: floorMeshPlane,
//                    materials: [
//                        SimpleMaterial(color: UIColor.black.withAlphaComponent(0.75), isMetallic: true)
//                    ]
//                )
//                
//                floorEntity.components.set(AssetsFloorEntityComponent())
//                containerEntity.name = "ContainerEntity"
//                
//                for assetComponent in assetComponents {
//                    guard let cgImage: CGImage = assetComponent.image?.cgImage,
//                          let asset: PHAsset = assetComponent.asset
//                    else { 
//                        continue
//                    }
//                    
//                    let texture: TextureResource = try! .generate(from: cgImage, options: .init(semantic: .hdrColor))
//                    
//                    var material: UnlitMaterial = .init()
//                    material.color = .init(tint: .white, texture: .init(texture))
//                    
//                    let entity: ModelEntity = .init(mesh: .generatePlane(width: 0.1, depth: 0.1), materials: [material])
//                    entity.name = asset.localIdentifier
//                    entity.components[AssetEntityComponent.self] = assetComponent
//                    
//                    // https://stackoverflow.com/a/65847268/17473716
//                    entity.generateCollisionShapes(recursive: false)
//                    containerEntity.addChild(entity, preservingWorldTransform: true)
//                }
//                
//                let anchor: ARAnchor = .init(name: "ContainerAnchor", transform: firstRaycast.worldTransform)
//                session.add(anchor: anchor)
//                
//                let anchorEntity: AnchorEntity = .init(anchor: anchor)
//                anchorEntity.name = "ContainerAnchor"
//                anchorEntity.anchoring = .init(anchor)
//                anchorEntity.addChild(containerEntity, preservingWorldTransform: true)
//                
//                arView.scene.addAnchor(anchorEntity)
//                self.assetComponents = nil
//            }
//        }
//    }
//    
//    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        MainActor.assumeIsolated {
//            guard let containerAnchor: ARAnchor = anchors.first(where: { $0.name == "ContainerAnchor" }) else {
//                return
//            }
//            
//            guard let containerEntities: [ModelEntity] = arView
//                .scene
//                .anchors
//                .first(where: { $0.anchoring == .init(containerAnchor) })?
//                .children
//                .compactMap({ $0 as? ModelEntity })
//            else {
//                return
//            }
//            
//            let children: [ModelEntity] = containerEntities
//                .map { $0.children }
//                .flatMap { $0 }
//                .compactMap { $0 as? ModelEntity }
//            
//            if let firstEntity: ModelEntity = children.first,
//               firstEntity.transform.translation.y != .zero {
//                return
//            }
//            
//            for (index, child) in children.enumerated() {
//                let row: Int = index / 6
//                let column: Int = index % 6
//                var transform: Transform = child.transform
//                
//                transform.translation = .init(
//                    x: CellLayout.cellPadding * Float(column + 1) + Float(column) * CellLayout.cellSize + (CellLayout.containerPadding + CellLayout.cellSize - CellLayout.containerSize) * 0.5,
//                    y: 0.01,
//                    z: CellLayout.cellPadding * Float(row + 1) + Float(row) * CellLayout.cellSize + (CellLayout.containerPadding + CellLayout.cellSize - CellLayout.containerSize) * 0.5
//                )
//                
//                child.move(to: transform, relativeTo: nil, duration: 1.0, timingFunction: .easeInOut)
//            }
//        }
//    }
//}
//
//extension ARPhotoPickerViewController: ARCoachingOverlayViewDelegate {
//    nonisolated func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
//        MainActor.assumeIsolated {
//            runConfiguration(with: coachingOverlayView.session)
//        }
//    }
//}
//
//#endif
