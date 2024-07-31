//
//  ARViewContainer.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        // Add Pan Gesture Recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Add Long Press Gesture Recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        arView.addGestureRecognizer(longPressGesture)

        // Add Rotation Gesture Recognizer
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)

        // Add Pinch Gesture Recognizer for Zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let image = selectedImage {
            let anchorEntity = AnchorEntity(world: .zero)
            let modelEntity = createImageEntity(image: image)
            modelEntity.generateCollisionShapes(recursive: true) // Ensure collision shapes are generated
            anchorEntity.addChild(modelEntity)
            uiView.scene.addAnchor(anchorEntity)
            context.coordinator.anchorEntities.append(anchorEntity)
            context.coordinator.modelEntities.append(modelEntity)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var anchorEntities: [AnchorEntity] = []
        var modelEntities: [ModelEntity] = []
        var selectedEntity: ModelEntity? // Track the selected entity
        var isTouchingImage = false
        var attachedPlane: ARRaycastQuery.TargetAlignment?
        var lastRotation: Float = 0.0 // Store the last rotation value
        var lastScale: Float = 1.0 // Store the last scale value

        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            let location = gesture.location(in: arView)

            if gesture.state == .began {
                let hits = arView.hitTest(location)
                if let firstHit = hits.first(where: { $0.entity is ModelEntity })?.entity as? ModelEntity {
                    isTouchingImage = true
                    selectedEntity = firstHit
                } else {
                    isTouchingImage = false
                    selectedEntity = nil
                }
            }

            if gesture.state == .changed && isTouchingImage {
                guard let selectedEntity = selectedEntity else { return }
                let query: ARRaycastQuery? = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)
                let results: [ARRaycastResult] = arView.session.raycast(query!)
                if let firstHit = results.first {
                    let transform = firstHit.worldTransform
                    if let anchorEntity = anchorEntities.first(where: { $0.children.contains(selectedEntity) }) {
                        anchorEntity.position = [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z]
                    }
                } else {
                    print("No hit detected.")
                }
            }

            if gesture.state == .ended || gesture.state == .cancelled {
                selectedEntity = nil
                isTouchingImage = false
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            if gesture.state == .began {
                let location = gesture.location(in: arView)
                let hits = arView.hitTest(location)

                if let firstHit = hits.first(where: { $0.entity is ModelEntity })?.entity as? ModelEntity, let index = modelEntities.firstIndex(of: firstHit) {
                    // Remove the model entity
                    modelEntities[index].removeFromParent()
                    anchorEntities[index].removeFromParent()
                    modelEntities.remove(at: index)
                    anchorEntities.remove(at: index)
                } else {
                    print("No hit detected on the model entity.")
                }
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            if gesture.state == .began {
                lastRotation = 0.0
            }

            let location = gesture.location(in: arView)
            let hits = arView.hitTest(location)

            if let firstHit = hits.first(where: { $0.entity is ModelEntity })?.entity as? ModelEntity {
                let rotation = Float(gesture.rotation - CGFloat(lastRotation))
                lastRotation = Float(gesture.rotation)
                firstHit.transform.rotation *= simd_quatf(angle: rotation, axis: [0, 0, 1])

                if gesture.state == .ended {
                    lastRotation = 0.0
                }
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            if gesture.state == .began {
                lastScale = 1.0
            }

            let location = gesture.location(in: arView)
            let hits = arView.hitTest(location)

            if let firstHit = hits.first(where: { $0.entity is ModelEntity })?.entity as? ModelEntity {
                let scale = Float(gesture.scale) / lastScale
                lastScale = Float(gesture.scale)
                firstHit.scale *= SIMD3<Float>(repeating: scale)

                if gesture.state == .ended {
                    lastScale = 1.0
                }
            }
        }
    }

    private func createImageEntity(image: UIImage) -> ModelEntity {
        let plane = MeshResource.generatePlane(width: 1.0, height: 1.0)
        let material = UnlitMaterial(color: .white)
        let modelEntity = ModelEntity(mesh: plane, materials: [material])

        let texture = try! TextureResource.generate(from: image.cgImage!, options: .init(semantic: nil))
        var materialWithTexture = UnlitMaterial()
        materialWithTexture.color = .init(texture: .init(texture))
        modelEntity.model?.materials = [materialWithTexture]

        return modelEntity
    }
}
