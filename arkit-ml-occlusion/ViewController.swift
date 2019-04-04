//
//  ViewController.swift
//  arkit-ml-occlusion
//
//  Created by Alexander on 04/04/2019.
//  Copyright © 2019 Aleksandr Gutrits. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Fritz

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private lazy var visionModel = FritzVisionPeopleSegmentationModel()
    
    var planes = [ARPlaneAnchor: SCNNode]()
    var planeColor = UIColor.init(hue: 0.5, saturation: 0.5, brightness: 0.5, alpha: 0.5)
    
    var maskNode : SCNNode!;
    var maskMaterial : SCNMaterial!;
    
    var currentBuffer: CVPixelBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        addTapGestureToSceneView()
        bilbordCreate()
        setupUIViews()
    }
    
    func setupUIViews() {
        let button = UIButton(frame: CGRect(x: 10, y: 10, width: 80, height: 30))
        button.backgroundColor = .gray
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 10)
        button.setTitle("Show mask", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        if (maskMaterial.colorBufferWriteMask == .all) {
            maskMaterial.colorBufferWriteMask = .alpha
            sender.setTitle("Show mask", for: .normal)
            return
        }
        maskMaterial.colorBufferWriteMask = .all
        sender.setTitle("Hide mask", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        currentBuffer = frame.capturedImage
        startDetection()
    }
    
    func bilbordCreate() {
        maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIColor.red
        maskMaterial.colorBufferWriteMask = .alpha
        
        let rectangle = SCNPlane(width: 0.0326, height: 0.058)
        rectangle.materials = [maskMaterial]
        
        maskNode = SCNNode(geometry: rectangle)
        maskNode?.eulerAngles = SCNVector3Make(0, 0, 0)
        maskNode?.position = SCNVector3Make(0, 0, -0.05)
        maskNode.renderingOrder = -1
        
        sceneView.pointOfView?.presentation.addChildNode(maskNode!)
    }
    
    let visionQueue = DispatchQueue(label: "com.vision.ARML.visionqueue")
    
    func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return uiImage
    }
    
    private func startDetection() {
        // To avoid force unwrap in VNImageRequestHandler
        guard let buffer = currentBuffer else { return }
        
        let image = FritzVisionImage(image: pixelBufferToUIImage(pixelBuffer: buffer))
        image.metadata = FritzVisionImageMetadata()
        let options = FritzVisionSegmentationModelOptions()
        options.imageCropAndScaleOption = .scaleFit
        
        visionQueue.async {
            // Run our CoreML Request
            self.visionModel.predict(image, options: options) { [weak self] (mask, error) in
                guard let mask = mask else { return }
                let maskImage = mask.toImageMask(of: FritzVisionPeopleClass.person, threshold: 0.70, minThresholdAccepted: 0.30)
                DispatchQueue.main.async {
                    self?.maskMaterial.diffuse.contents = maskImage
                }
            }
            
            // The resulting image (mask) is available as observation.pixelBuffer
            // Release currentBuffer when finished to allow processing next frame
            self.currentBuffer = nil
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = planeColor
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let translation = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y + Float(boxGeometry.height * 0.5), hitTestResult.worldTransform.columns.3.z)
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        let cube = SCNNode(geometry: boxGeometry)
        
        cube.position = SCNVector3(x,y,z)
        sceneView.scene.rootNode.addChildNode(cube)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
