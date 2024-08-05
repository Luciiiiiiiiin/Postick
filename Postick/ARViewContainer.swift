//
//  ARViewContainer.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//  THis is the file that takes charge of control of the AR View

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
        coachingOverlay.goal = .verticalPlane // Set goal as needed
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
        // Ensure there's a selected image; if not, exit the function.
        guard let image = selectedImage else { return }

        // Generate a unique identifier for the image. If the image already has an accessibilityIdentifier, use it.
        // Otherwise, generate a new UUID.
        let imageIdentifier = image.accessibilityIdentifier ?? UUID().uuidString
        print("Updating UIView with image: \(imageIdentifier)")

        // Check if an anchor with the same image identifier already exists in the modelEntities array.
        // If it exists, skip adding the new image to avoid duplication.
        if context.coordinator.modelEntities.contains(where: { $0.name == imageIdentifier }) {
            print("Image with identifier \(imageIdentifier) already exists. Skipping.")
            return
        }

        // Create a new anchor entity at the world origin (position [0, 0, 0]).
        let anchorEntity = AnchorEntity(world: .zero)
        
        // Create a model entity from the selected image.
        let modelEntity = createImageEntity(image: image)
        
        // Assign the unique identifier to the model entity's name property.
        modelEntity.name = imageIdentifier
        
        // Generate collision shapes for the model entity to enable interaction with gestures.
        modelEntity.generateCollisionShapes(recursive: true)
        
        // Add the model entity as a child of the anchor entity.
        anchorEntity.addChild(modelEntity)
        
        // Add the anchor entity to the AR view's scene.
        uiView.scene.addAnchor(anchorEntity)
        
        // Append the new anchor entity and model entity to the coordinator's respective arrays for tracking.
        context.coordinator.anchorEntities.append(anchorEntity)
        context.coordinator.modelEntities.append(modelEntity)

        // Clear the selected image to prevent it from being re-added in future updates.
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
        // Calculate the aspect ratio of the image
        let aspectRatio = image.size.width / image.size.height

        // Create a plane mesh with dimensions that match the image's aspect ratio
        let planeWidth: Float = 1.0
        let planeHeight: Float = 1.0 / Float(aspectRatio)
        let plane = MeshResource.generatePlane(width: planeWidth, height: planeHeight)

        // Create a default unlit material
        let material = UnlitMaterial(color: .white)

        // Create a model entity using the plane mesh and the white material
        let modelEntity = ModelEntity(mesh: plane, materials: [material])

        // Create a texture resource from the UIImage's CGImage
        let texture = try! TextureResource.generate(from: image.cgImage!, options: .init(semantic: nil))

        // Create a new unlit material and set its color to the generated texture
        var materialWithTexture = UnlitMaterial()
        materialWithTexture.color = .init(texture: .init(texture))

        // Apply the textured material to the model entity
        modelEntity.model?.materials = [materialWithTexture]

        // Set the initial scale to be smaller
        let initialScale: Float = 0.5 // Adjust this value to set the desired initial size
        modelEntity.scale = [initialScale, initialScale, initialScale]

        // Set a unique identifier for the model entity
        modelEntity.name = image.accessibilityIdentifier ?? UUID().uuidString

        return modelEntity
    }


}


