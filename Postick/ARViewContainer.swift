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
    var onPhotoCaptured: (UIImage) -> Void

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical] // Enable plane detection
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        // Add ARCoachingOverlayView
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane // Set goal as needed
        arView.addSubview(coachingOverlay)
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.setActive(true, animated: true)

        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        arView.addGestureRecognizer(longPressGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        // Pass the ARView instance to the Coordinator
        context.coordinator.arView = arView

        // Add notification observer for photo capture
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.capturePhoto), name: Notification.Name("capturePhoto"), object: nil)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let image = selectedImage else { return }

        let imageIdentifier = image.accessibilityIdentifier ?? UUID().uuidString
        print("Updating UIView with image: \(imageIdentifier)")

        // Check if there's already an anchor with the image
        if context.coordinator.modelEntities.contains(where: { $0.name == imageIdentifier }) {
            print("Image with identifier \(imageIdentifier) already exists. Skipping.")
            return
        }

        let anchorEntity = AnchorEntity(world: .zero)
        let modelEntity = createImageEntity(image: image)
        modelEntity.name = imageIdentifier
        modelEntity.generateCollisionShapes(recursive: true) // Ensure collision shapes are generated
        anchorEntity.addChild(modelEntity)
        uiView.scene.addAnchor(anchorEntity)
        context.coordinator.anchorEntities.append(anchorEntity)
        context.coordinator.modelEntities.append(modelEntity)

        // Clear selected image to prevent re-adding
        selectedImage = nil
        print("Added image with identifier \(imageIdentifier) to AR view.")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onPhotoCaptured: onPhotoCaptured)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var onPhotoCaptured: (UIImage) -> Void
        var anchorEntities: [AnchorEntity] = []
        var modelEntities: [ModelEntity] = []
        var selectedEntity: ModelEntity? // Track the selected entity
        var isTouchingImage = false
        var attachedPlane: ARRaycastQuery.TargetAlignment?
        var lastRotation: Float = 0.0 // Store the last rotation value
        var lastScale: Float = 1.0 // Store the last scale value
        weak var arView: ARView? // Store a weak reference to the ARView

        init(_ parent: ARViewContainer, onPhotoCaptured: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onPhotoCaptured = onPhotoCaptured
            super.init()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }

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
            guard let arView = arView else { return }

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
            guard let arView = arView else { return }

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
            guard let arView = arView else { return }

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

        @objc func capturePhoto() {
            guard let arView = arView else { return }
            
            let size = arView.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            arView.drawHierarchy(in: arView.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let capturedImage = image {
                onPhotoCaptured(capturedImage)
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

        // Set the initial scale to be smaller
        let initialScale: Float = 0.5 // Adjust this value to set the desired initial size
        modelEntity.scale = [initialScale, initialScale, initialScale]

        // Set a unique identifier for the model entity
        modelEntity.name = image.accessibilityIdentifier ?? UUID().uuidString

        return modelEntity
    }
}

