//
//  ImmersiveEffectView.swift
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit
import CoreMedia

@_expose(Cxx)
public struct ImmersiveView: View {
    @_expose(Cxx)
    public static func makeHostingController() -> UIViewController {
        MainActor.assumeIsolated { 
            UIHostingController(rootView: ImmersiveView())
        }
    }
    
    @MainActor @State private var updateID: UUID?
    @MainActor @State private var requests: Requests
    
    @MainActor 
    init() {
        requests = .init()
    }
    
    public var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                
                addPendingEffectComponents(content: content, sceneFrame: sceneFrame)
            } update: { content in
                _ = updateID
                
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                
                updateFloorCollisionEntity(with: content, sceneFrame: sceneFrame)
                addPendingEffectComponents(content: content, sceneFrame: sceneFrame)
                removePendingEffectComponents(content: content)
            }
            .task {
                for await notification in NotificationCenter.default.notifications(named: .ImmersiveEffectAddEffect) {
                    guard 
                        let userInfo: [AnyHashable: Any] = notification.userInfo,
                        let requestID: UUID = userInfo[ImmersiveEffectReqestIDKey] as? UUID,
                        !requests.toBeAddedEffectComponents.contains(where: { $0.requestID == requestID }),
                        !requests.tasksByEffectComponent.keys.contains(where: { $0.requestID == requestID }),
                        let rawValue: UInt = userInfo[ImmersiveEffectNumberKey] as? UInt,
                        let effect: ImmersiveEffect = .init(rawValue: rawValue),
                        let duration: CMTime = (userInfo[ImmersiveEffectDurationTimeValueKey] as? NSValue)?.timeValue
                    else {
                        continue
                    }
                    
                    let effectComponent: EffectComponent = .init(
                        immersiveEffect: effect,
                        requestID: requestID,
                        duration: duration
                    )
                    
                    requests.toBeAddedEffectComponents.append(effectComponent)
                    
                    updateID = .init()
                }
            }
            .task {
                for await notification in NotificationCenter.default.notifications(named: .ImmersiveEffectRemoveEffect) {
                    fatalError("TODO")
                }
            }
            .task {
                for await notification in NotificationCenter.default.notifications(named: UIScene.didDisconnectNotification) {
                    guard 
                        let scene: UIScene = notification.object as? UIScene,
                        scene.session.role == .immersiveSpaceApplication
                    else {
                        continue
                    }
                    
                    // TODO: 정확히 자기 자신의 Scene인지 알기
                    
                    cancelTasks()
                }
            }
            .onDisappear { 
                cancelTasks()
            }
        }
    }
    
    @MainActor
    private func cancelTasks() {
        requests
            .tasksByEffectComponent
            .forEach { $0.value.cancel() }
    }
    
    @MainActor
    private func addPendingEffectComponents(content: RealityViewContent, sceneFrame: BoundingBox) {
        let toBeAddedEffectComponents: [EffectComponent] = requests.toBeAddedEffectComponents
        
        guard !toBeAddedEffectComponents.isEmpty else {
            return
        }
        
        requests.toBeAddedEffectComponents.removeAll()
        
        for effectComponent in toBeAddedEffectComponents {
            var addedEntities: [Entity] = []
            
            switch effectComponent.immersiveEffect {
            case .fallingBalls:
                addedEntities.append(addFloorCollisionEntity(into: content, sceneFrame: sceneFrame))
                addedEntities.append(contentsOf: addSpheres(into: content, sceneFrame: sceneFrame))
            case .fireworks:
                addedEntities.append(addFireworkEntity(into: content, sceneFrame: sceneFrame))
            case .impact:
                addedEntities.append(addImpactEntity(into: content, sceneFrame: sceneFrame))
            case .magic:
                addedEntities.append(addMagicEntity(into: content, sceneFrame: sceneFrame))
            case .rain:
                addedEntities.append(addRainEntity(into: content, sceneFrame: sceneFrame))
            case .snow:
                addedEntities.append(addSnowEntity(into: content, sceneFrame: sceneFrame))
            case .sparks:
                addedEntities.append(contentsOf: addSparksEntity(into: content, sceneFrame: sceneFrame))
            @unknown default:
                fatalError()
            }
            
            for entity in addedEntities {
                entity.components.set(effectComponent)
            }
            
            requests.tasksByEffectComponent[effectComponent] = removingEffectComponentTask(effectComponent)
        }
    }
    
    @MainActor
    private func removePendingEffectComponents(content: RealityViewContent) {
        let toBeRemovedEffectComponents: [EffectComponent] = requests.toBeRemovedEffectComponents
        
        guard !toBeRemovedEffectComponents.isEmpty else {
            return
        }
        
        requests.toBeRemovedEffectComponents.removeAll()
        
        content
            .entities
            .filter { entity in
                guard let effectComponent: EffectComponent = entity.components[EffectComponent.self] else {
                    return false
                }
                
                return toBeRemovedEffectComponents.contains(effectComponent)
            }
            .forEach { entity in
                content.remove(entity)
            }
    }
    
    private func removingEffectComponentTask(_ effectComponent: EffectComponent) -> Task<Void, Never> {
        .init { @MainActor in
            defer {
                requests.tasksByEffectComponent.removeValue(forKey: effectComponent)
            }
            
            do {
                try await Task.sleep(nanoseconds: UInt64(effectComponent.duration.convertScale(Int32(1E9), method: .default).value))
                requests.toBeRemovedEffectComponents.append(effectComponent)
                updateID = .init()
            } catch {
                print("Cancelled")
            }
        }
    }
    
    private func addSpheres(into content: RealityViewContent, sceneFrame: BoundingBox) -> [Entity] {
        return (0..<50)
            .map { index in
                let sphereEntity: Entity = .metalicSphere(sceneFrame: sceneFrame)
                sphereEntity.name = "SphereEntity_\(index)"
                
                content.add(sphereEntity)
                
                return sphereEntity
            }
    }
    
    private func addFloorCollisionEntity(into content: RealityViewContent, sceneFrame: BoundingBox) -> Entity {
        let boxSize: Float = 30.0
        
        let floorCollisionEntity: ModelEntity = .init(
            mesh: .generateBox(
                width: boxSize,
                height: 1E-3,
                depth: boxSize
            ),
            materials: [
                SimpleMaterial(color: .init(white: 1.0, alpha: 0.1), isMetallic: false)
            ]
        )
        
        floorCollisionEntity.position = floorCollisionEntityLocation(sceneFrame: sceneFrame)
        
        let boxShape: ShapeResource = .generateBox(
            width: boxSize,
            height: 1E-3,
            depth: boxSize
        )
        
        let collisionComponent: CollisionComponent = .init(
            shapes: [boxShape],
            isStatic: true
        )
        
        floorCollisionEntity.components.set(collisionComponent)
        
        let physicsBodyComponent: PhysicsBodyComponent = .init(
            shapes: [boxShape],
            mass: 1.0,
            mode: .static
        )
        
        floorCollisionEntity.components.set(physicsBodyComponent)
        floorCollisionEntity.components.set(OwnFloorCollosionComponent())
        
        content.add(floorCollisionEntity)
        
        return floorCollisionEntity
    }
    
    private func updateFloorCollisionEntity(with content: RealityViewContent, sceneFrame: BoundingBox) {
        for entity in content.entities {
            if entity.components.has(OwnFloorCollosionComponent.self) {
                entity.position = floorCollisionEntityLocation(sceneFrame: sceneFrame)
            }
        }
    }
    
    private func floorCollisionEntityLocation(sceneFrame: BoundingBox) -> SIMD3<Float> {
        let center: SIMD3<Float> = sceneFrame.center
        return .init(x: center.x, y: .zero, z: center.z)
    }
    
    private func addFireworkEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> Entity {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.fireworks
        
        particleEmitterComponent.birthLocation = .surface
        particleEmitterComponent.mainEmitter.birthRate = 300.0
        particleEmitterComponent.mainEmitter.lifeSpan = 3.0
        particleEmitterComponent.mainEmitter.lifeSpanVariation = 0.2
        particleEmitterComponent.mainEmitter.dampingFactor = 0.005
        
        particleEmitterComponent.mainEmitter.size = 0.015
        particleEmitterComponent.mainEmitter.attractionStrength = -0.35
        particleEmitterComponent.mainEmitter.sizeVariation = 0.002
        particleEmitterComponent.emitterShapeSize = .init(x: 5.0, y: .zero, z: 5.0)
        
        particleEmitterComponent.spawnedEmitter?.size = 0.01
        particleEmitterComponent.spawnedEmitter?.sizeVariation = 0.05
        
        entity.components.set(particleEmitterComponent)
        
        entity.components.set(
            ModelComponent(
                mesh: .generateBox(
                    size: [
                        particleEmitterComponent.emitterShapeSize.x * 2.0,
                        0.001,
                        particleEmitterComponent.emitterShapeSize.z * 2.0
                    ]
                ),
                materials: [
                    UnlitMaterial(color: .blue.withAlphaComponent(0.3))
                ]
            )
        )
        
        entity.position = .init(
            x: sceneFrame.center.x,
            y: sceneFrame.min.y,
            z: sceneFrame.min.z - 1.5
        )
        
        content.add(entity)
        
        return entity
    }
    
    private func addImpactEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> Entity {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.impact
        particleEmitterComponent.mainEmitter.size = 0.3
        particleEmitterComponent.mainEmitter.lifeSpan = 2.0
        particleEmitterComponent.mainEmitter.birthRate = 2000.0
        particleEmitterComponent.isEmitting = true
        
        particleEmitterComponent.mainEmitter.color = .evolving(
            start: .random(a: .red, b: .systemPink),
            end: .random(a: .cyan, b: .green)
        )
        
        entity.components.set(particleEmitterComponent)
        
        entity.position = .init(
            x: sceneFrame.center.x,
            y: 2.5,
            z: sceneFrame.min.z - 3.0
        )
        
        content.add(entity)
        
        return entity
    }
    
    private func addMagicEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> Entity {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.magic
        
        particleEmitterComponent.mainEmitter.size = 1.0
        particleEmitterComponent.mainEmitter.birthRate = 400.0
        particleEmitterComponent.mainEmitter.lifeSpan = 1.0
        particleEmitterComponent.mainEmitter.angularSpeed = 0.7
        
        particleEmitterComponent.emitterShapeSize = .init(x: 5.0, y: .zero, z: 5.0)
        
        entity.components.set(particleEmitterComponent)
        
        entity.position = .init(
            x: sceneFrame.center.x,
            y: sceneFrame.min.y + 1.0,
            z: sceneFrame.min.z - 3.0
        )
        
        content.add(entity)
        
        return entity
    }
    
    private func addRainEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> Entity {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.rain
        
        particleEmitterComponent.mainEmitter.birthRate = 30000.0
        particleEmitterComponent.mainEmitter.lifeSpan = 0.5
        particleEmitterComponent.mainEmitter.size = 0.002
        particleEmitterComponent.emitterShapeSize = .init(x: 5.0, y: .zero, z: 5.0)
        particleEmitterComponent.birthDirection = .local
        
        entity.components.set(particleEmitterComponent)
        
        entity.position = .init(
            x: sceneFrame.center.x,
            y: sceneFrame.min.y + 4.0,
            z: sceneFrame.min.z - 3.0
        )
        
        content.add(entity)
        
        return entity
    }
    
    private func addSnowEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> Entity {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.snow
        
        particleEmitterComponent.mainEmitter.birthRate = 10000.0
        particleEmitterComponent.mainEmitter.lifeSpan = 20.0
        particleEmitterComponent.mainEmitter.size = 0.002
        particleEmitterComponent.emitterShapeSize = .init(x: 5.0, y: .zero, z: 5.0)
        particleEmitterComponent.birthDirection = .local
        
        entity.components.set(particleEmitterComponent)
        
        entity.position = .init(
            x: sceneFrame.center.x,
            y: sceneFrame.min.y + 3.0,
            z: sceneFrame.min.z - 3.0
        )
        
        content.add(entity)
        
        return entity
    }
    
    private func addSparksEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) -> [Entity] {
        let entity: Entity = .init()
        
        var particleEmitterComponent: ParticleEmitterComponent = .Presets.sparks
        particleEmitterComponent.mainEmitter.lifeSpan = 1.0
        particleEmitterComponent.mainEmitter.birthRate = 30000.0
        particleEmitterComponent.mainEmitter.spreadingAngle = .pi
        particleEmitterComponent.mainEmitter.color = .evolving(
            start: .random(a: .white, b: .magenta),
            end: .random(a: .cyan, b: .red)
        )
        
        entity.components.set(particleEmitterComponent)
        
        entity.position = .init(
            x: -2.0,
            y: 2.0,
            z: sceneFrame.min.z - 2.0
        )
        
        content.add(entity)
        
        let copied_1: Entity = entity.clone(recursive: true)
        copied_1.position.x = 2.0
        content.add(copied_1)
        
        let copied_2: Entity = entity.clone(recursive: true)
        copied_2.position.x = .zero
        copied_2.position.y = 2.8
        content.add(copied_2)
        
        return [entity, copied_1, copied_2]
    }
}

fileprivate struct OwnFloorCollosionComponent: Component {}

#endif
