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
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        // Add Pan Gesture Recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Add Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showSceneUnderstanding, .showAnchorGeometry, .showAnchorOrigins]

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let image = selectedImage, context.coordinator.anchorEntity == nil {
            let anchorEntity = AnchorEntity(world: .zero)
            let modelEntity = createImageEntity(image: image)
            anchorEntity.addChild(modelEntity)
            uiView.scene.addAnchor(anchorEntity)
            context.coordinator.anchorEntity = anchorEntity
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var anchorEntity: AnchorEntity?
        var isTouchingImage = false
        var attachedPlane: ARRaycastQuery.TargetAlignment?

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
                print(isTouchingImage)
            }

            if gesture.state == .changed && isTouchingImage {
                guard let alignment = attachedPlane else { return }
                let query: ARRaycastQuery? = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: alignment)
                let results:[ARRaycastResult] = arView.session.raycast(query!)
                if let firstHit = results.first {
                    let transform = firstHit.worldTransform
                    if let anchorEntity = anchorEntity {
                        anchorEntity.position = [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z]
                        print("Anchor Entity Position: \(anchorEntity.position)")
                    }
                } else {
                    print("No hit detected.")
                }
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            let location = gesture.location(in: arView)
            let hits = arView.hitTest(location)

            if let firstHit = hits.first {
                print("Tapped entity: \(firstHit.entity)")
                // Handle tap on the model entity here
            } else {
                print("No hit detected on the model entity.")
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
