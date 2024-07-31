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
        if let image = selectedImage, context.coordinator.anchorEntity == nil {
            let anchorEntity = AnchorEntity(world: .zero)
            let modelEntity = createImageEntity(image: image)
            modelEntity.generateCollisionShapes(recursive: true) // Ensure collision shapes are generated
            anchorEntity.addChild(modelEntity)
            uiView.scene.addAnchor(anchorEntity)
            context.coordinator.anchorEntity = anchorEntity
            context.coordinator.modelEntity = modelEntity // Store reference to the model entity
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var anchorEntity: AnchorEntity?
        var modelEntity: ModelEntity? // Reference to the model entity
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
                let hits = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                if let firstHit = hits.first {
                    isTouchingImage = true
                    attachedPlane = firstHit.targetAlignment
                } else {
                    isTouchingImage = false
                }
            }

            if gesture.state == .changed && isTouchingImage {
                guard let alignment = attachedPlane else { return }
                let query: ARRaycastQuery? = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: alignment)
                let results: [ARRaycastResult] = arView.session.raycast(query!)
                if let firstHit = results.first {
                    let transform = firstHit.worldTransform
                    if let anchorEntity = anchorEntity {
                        anchorEntity.position = [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z]
                    }
                } else {
                    print("No hit detected.")
                }
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            if gesture.state == .began {
                let location = gesture.location(in: arView)
                let hits = arView.hitTest(location)

                if let firstHit = hits.first, let modelEntity = modelEntity, firstHit.entity == modelEntity {
                    // Remove the model entity
                    modelEntity.removeFromParent()
                    anchorEntity?.removeFromParent()
                    self.modelEntity = nil
                    self.anchorEntity = nil
                } else {
                    print("No hit detected on the model entity.")
                }
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let modelEntity = modelEntity else { return }

            if gesture.state == .began {
                lastRotation = 0.0
            }

            let rotation = Float(gesture.rotation - CGFloat(lastRotation))
            lastRotation = Float(gesture.rotation)
            modelEntity.transform.rotation *= simd_quatf(angle: rotation, axis: [0, 0, 1])

            if gesture.state == .ended {
                lastRotation = 0.0
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let modelEntity = modelEntity else { return }

            if gesture.state == .began {
                lastScale = 1.0
            }

            let scale = Float(gesture.scale) / lastScale
            lastScale = Float(gesture.scale)
            modelEntity.scale *= SIMD3<Float>(repeating: scale)

            if gesture.state == .ended {
                lastScale = 1.0
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
