//
//  ViewController.swift
//  playground
//
//  Created by Eduardo Cunha on 18/12/19.
//  Copyright © 2019 Eduardo Cunha. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load remote image
        let context = CIContext()

        let ambushImage = try! CIImage(data: Data(contentsOf: URL(string: "http://cunha.local:8000/ambush.jpeg")!))!
        
        let ambushReferenceImage = ARReferenceImage(context.createCGImage(ambushImage, from: ambushImage.extent)!, orientation: .up, physicalWidth: 0.06)
        ambushReferenceImage.name = "Ambush"
        
        var ambushSet = Set<ARReferenceImage>()
        ambushSet.insert(ambushReferenceImage)
        
        // Load bundled images
        guard let matthiasSet = ARReferenceImage.referenceImages(inGroupNamed: "Matthias", bundle: Bundle.main) else {
            fatalError("Failed to load reference images from resources")
        }
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = ambushSet.union(matthiasSet)
        configuration.maximumNumberOfTrackedImages = 1

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            self.addInfoNodes(for: imageAnchor, on: node)
        }
        
        return node
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: sceneView)
        
        print("Received touch event at \(touchLocation)")
        
        let hitTestResults = sceneView.hitTest(touchLocation)
        
        if let node = hitTestResults.first?.node,
            let name = node.name,
            name.contains("Plane") {
            print("Animating hit node: \(node.name ?? "No name")")
            
            let scaleDown = SCNAction.scale(by: 0.9, duration: 0.15)
            let scaleUp = scaleDown.reversed()
            let animation = SCNAction.sequence([scaleDown, scaleUp])
            
            node.runAction(animation)
        }
    }
    
    func addInfoNodes(for anchor: ARImageAnchor, on root: SCNNode) {
        print("Begin info node build")
        
        let name = anchor.referenceImage.name!
        let size = anchor.referenceImage.physicalSize
        
        print("Image: \(name) - Size: \(size)")
        
        let plane = SCNPlane(width: size.width, height: size.height)
        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        plane.cornerRadius = 0.005
        
        plane.name = "Plane - \(name)"
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = anchor.referenceImage.name!
        planeNode.eulerAngles.x = -.pi / 2
        
        let titleText = SCNText(string: name, extrusionDepth: 0.0)
        titleText.font = UIFont(name: "Helvetica", size: 12)
        
        let titleNode = SCNNode(geometry: titleText)
        titleNode.position.x = Float(size.width / 1.9)
        titleNode.eulerAngles.x = -.pi / 2
        
        print("Title node local position: \(titleNode.position)")
        
        let description = descriptionText(for: name)
        
        let descriptionText = SCNText(string: description, extrusionDepth: 0.0)
        descriptionText.font = UIFont(name: "Helvetica", size: 8)
        
        let descriptionNode = SCNNode(geometry: descriptionText)
        descriptionNode.position.y = -8
        
        print("Description node local position: \(descriptionNode.position)")
        
        titleNode.addChildNode(descriptionNode)
        
        titleNode.scale = SCNVector3(0.003, 0.003, 0.003)
        
        root.addChildNode(planeNode)
        root.addChildNode(titleNode)
    }
    
    func descriptionText(for name: String) -> String {
        if name == "Ambush" {
            return "A Digital Product Studio\nfor Hypergrowth Companies"
        }
        
        return "Very Beast"
    }
}
