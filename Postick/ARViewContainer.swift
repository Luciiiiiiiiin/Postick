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
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic

        arView.session.run(config)

        // Add Pan Gesture Recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        // Used to debug
        //arView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showSceneUnderstanding, .showAnchorGeometry, .showAnchorOrigins]

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let image = selectedImage, context.coordinator.anchorEntity == nil {
            let anchorEntity = AnchorEntity(plane: .any)
            let modelEntity = createImageEntity(image: image)
            modelEntity.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            anchorEntity.addChild(modelEntity)
            uiView.scene.addAnchor(anchorEntity)
            context.coordinator.anchorEntity = anchorEntity
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ARViewContainer
        var anchorEntity: AnchorEntity?

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            let location = gesture.location(in: arView)
            if gesture.state == .changed {
                let hits = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                if let firstHit = hits.first {
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
