//
//  ImmersiveEffectView.swift
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit

@_expose(Cxx)
public struct ImmersiveView: View {
    @_expose(Cxx)
    public static func makeHostingController() -> UIViewController {
        UIHostingController(rootView: ImmersiveView())
    }
    
    @State private var requestedEffect: ImmersiveEffect?
    
    @State private var buffer: ManagedBuffer<Void, ImmersiveEffect?> = .create(minimumCapacity: 1, makingHeaderWith: { buffer in
        buffer.withUnsafeMutablePointerToElements { ptr in
            ptr.initialize(to: nil)
        }
    })
    
    public var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                
                buffer.withUnsafeMutablePointerToElements { ptr in
                    ptr.pointee = nil
                }
                
                updateEffects(content: content, sceneFrame: sceneFrame)
            } update: { content in
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                
                updateEffects(content: content, sceneFrame: sceneFrame)
            }
            .task {
                for await notification in NotificationCenter.default.notifications(named: .ImmersiveEffectDidSelectEffect) {
                    guard let rawValue: UInt = notification.userInfo?[ImmersiveEffectSelectedEffectKey] as? UInt,
                          let effect: ImmersiveEffect = .init(rawValue: rawValue)
                    else {
                        continue
                    }
                    
                    requestedEffect = effect
                }
            }
        }
    }
    
    private func updateEffects(content: RealityViewContent, sceneFrame: BoundingBox) {
        let isEqual: Bool = buffer.withUnsafeMutablePointerToElements { ptr in
            let result: Bool = ptr.pointee == requestedEffect
            ptr.pointee = requestedEffect
            return result
        }
        
        guard !isEqual else {
            updateFloorCollisionEntity(with: content, sceneFrame: sceneFrame)
            return
        }
        
        removeSpheres(from: content)
        removeFloorCollisionEntity(from: content)
        removeParticleEmitterEntity(from: content)
        
        switch requestedEffect {
        case .fallingBalls:
            addFloorCollisionEntity(into: content, sceneFrame: sceneFrame)
            addSpheres(into: content, sceneFrame: sceneFrame)
        case .fireworks:
            addFireworkEntity(into: content, sceneFrame: sceneFrame)
        case .impact:
            addImpactEntity(into: content, sceneFrame: sceneFrame)
        case .magic:
            addMagicEntity(into: content, sceneFrame: sceneFrame)
        case .rain:
            addRainEntity(into: content, sceneFrame: sceneFrame)
        case .snow:
            addSnowEntity(into: content, sceneFrame: sceneFrame)
        case .sparks:
            addSparksEntity(into: content, sceneFrame: sceneFrame)
        case nil:
            break
        case .some(_):
            fatalError()
        }
    }
    
    private func addSpheres(into content: RealityViewContent, sceneFrame: BoundingBox) {
        for index in 0..<50 {
            let sphereEntity: Entity = .metalicSphere(sceneFrame: sceneFrame)
            sphereEntity.name = "SphereEntity_\(index)"
            sphereEntity.components.set(OwnSphereComponent())
            
            content.add(sphereEntity)
        }
    }
    
    private func removeSpheres(from content: RealityViewContent) {
        content.entities.removeAll { entity in
            return entity.components.has(OwnSphereComponent.self)
        }
    }
    
    private func addFloorCollisionEntity(into content: RealityViewContent, sceneFrame: BoundingBox) {
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
    }
    
    private func removeFloorCollisionEntity(from content: RealityViewContent) {
        content
            .entities
            .removeAll { entity in
                return entity.components.has(OwnFloorCollosionComponent.self)
            }
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
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
    
    private func addImpactEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
    
    private func addMagicEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
    
    private func addRainEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
    
    private func addSnowEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
    
    private func addSparksEntity(
        into content: RealityViewContent,
        sceneFrame: BoundingBox
    ) {
        let entity: Entity = .init()
        
        entity.components.set(OwnParticleEmitterComponent())
        
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
    }
     
    private func removeParticleEmitterEntity(from content: RealityViewContent) {
        content
            .entities
            .removeAll { entity in
                return entity.components.has(OwnParticleEmitterComponent.self)
            }
    }
}

fileprivate struct OwnSphereComponent: Component {}
fileprivate struct OwnFloorCollosionComponent: Component {}
fileprivate struct OwnParticleEmitterComponent: Component {}

#endif
