//
//  ViewController.swift
//  HooLens
//
//  Created by Brendon Ho on 6/6/19.
//  Copyright © 2019 Banjo. All rights reserved.
//

import UIKit
import SceneKit
import SceneKit.ModelIO
import Vision
import Photos
import ARKit
import DeckTransition
import NVActivityIndicatorView
import Kanna
import Alamofire
import Firebase
import FirebaseDatabase

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var slideView: UIView!
    var pars:[String] = []
    var fetchingResults = false
    var nutrition : [SCNNode] = []
    var buttons : [SCNNode] = []
    var urlEnd: String = ""
    var ref: DatabaseReference!
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    let visio = VisionService()
    
    var tapGesture = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        slideView.layer.cornerRadius = 30
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.historyUp))
        upSwipe.direction = .up;
        self.view.addGestureRecognizer(upSwipe);
        
        
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func historyUp(){
        performSegue(withIdentifier: "MoveToHistory", sender: nil)
        let modal = HistoryViewController()
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer){
        
        print("Screen Hit")
        print("1----------------")
        let cardHitTestResults = sceneView.hitTest(gestureRecognize.location(in: sceneView), options: nil)
        
        for result in cardHitTestResults {
            print("CARD HIT")
            print(result)
            if buttons.contains(result.node) {
                guard let components = result.node.name?.components(separatedBy: "C==3") else {
                    print("Malformed node name")
                    continue
                }
                
                
                if let dataFromString = components[1].data(using: .utf8, allowLossyConversion: false) {

                    performSegue(withIdentifier: "arToWeb", sender: nil)
                    
                }
                
                
                
                return
            }
            if nutrition.contains(result.node) {
                //remove all nodes, parents and children
                result.node.parent?.childNodes[0].runAction(SCNAction.scale(to: 0.0, duration: 0.3) )
                result.node.runAction(SCNAction.scale(to: 0.0, duration: 0.3) )
                result.node.parent?.childNodes[0].runAction(SCNAction.fadeOpacity(to: 0.0, duration: 0.3) )
                result.node.runAction(SCNAction.fadeOpacity(to: 0.0, duration: 0.3) )
                
                result.node.runAction(SCNAction.wait(duration: 0.5), completionHandler: {
                    result.node.parent?.removeFromParentNode()
                    self.buttons.remove(at: self.nutrition.index(of: result.node)!)
                    self.nutrition.remove(at: self.nutrition.index(of: result.node)!)
                })
                return
            }
            for node in nutrition {
                if result.node == node.parent {
                    return
                }
            }
        }
        
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint])
        
        if let closestResult = arHitTestResults.first{
            
            print("2----------------")
            
            let transform : matrix_float4x4 = closestResult.worldTransform
            //sceneView.session.add(anchor: ARAnchor(transform: transform))
            let worldCoord = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
            if pixbuff == nil { return }
            let ciImage = CIImage(cvPixelBuffer: pixbuff!)
            var image = convertCItoUIImage(cmage: ciImage)
            image = image.crop(to: CGSize(width: 299, height: 299))
            image = image.zoom(to: 4.0) ?? image
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    print("Saved successfully")
                    // Saved successfully!
                }
                else if let error = error {
                    // Save photo failed with error
                }
                else {
                    // Save photo failed with no error
                }
            })
            
            print("Sending Image")
            if fetchingResults == true {
                return
            } else {
                fetchingResults = true
                activityIndicatorView.alpha = 1.0
                activityIndicatorView.startAnimating()
            }
            
            visio.detectObject(image: ciImage){ [weak self] guess in
                guard let `self` = self else{
                    
                    return
                    
                }
                self.urlEnd = guess
                print(self.convertToURLable(string: guess))
                self.scrape(tailURL: guess, coord: worldCoord)
                self.fetchingResults = false
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.activityIndicatorView.alpha = 0.0;
                }
                self.ref = Database.database().reference()
                let sendDict : [String:Any] = ["value": guess,
                                               "date": Date().string(format: "MM/dd/yyyy")]
                self.ref.child("history").childByAutoId().setValue(sendDict)
                //print(self.pars[0])
                
            }
            
        }
        
    }
    
    func convertCItoUIImage(cmage:CIImage) -> UIImage{
        let context:CIContext = CIContext.init(options: nil)
        
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        return UIImage(cgImage: cgImage)
    }
    
    func convertToURLable(string: String) -> String{
        
        var newString = string
        
        if(string.contains(" ")){
            
            newString = string.replacingOccurrences(of: " ", with: "_")
            
        }
        
        return newString
        
    }
    
    func scrape(tailURL: String, coord: SCNVector3) -> Void{
        
        Alamofire.request("http://en.wikipedia.org/wiki/\(convertToURLable(string: tailURL))").responseString{ response in
            
            print("\(response.result.isSuccess)")
            
            if let html = response.result.value {
                
                self.parseHTML(html: html, guess: tailURL, coord: coord)
                
            }
            
        }
        
    }
    
    func parseHTML(html: String, guess: String, coord: SCNVector3) -> Void {
        
        if let doc = try? HTML(html: html, encoding: .utf8){
            
            for show in doc.css("p") {
                
                // Strip the string of surrounding whitespace.
                let showString = show.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // All text involving shows on this page currently start with the weekday.
                // Weekday formatting is inconsistent, but the first three letters are always there.
                //print(showString)
                pars.append(showString)
                
            }
            
        }
        
        getFirstText()
        self.makeBillBoard(titleString: guess, paragraphString: self.pars[0], coord: coord)
        pars = []
    }
    
    func getFirstText(){
        
        while(pars[0] == ""){
            
            pars.remove(at: 0)
            
        }
        
    }
    
    func makeBillBoard(titleString: String, paragraphString: String, coord: SCNVector3){
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        let textNode = SCNNode()
        textNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        textNode.opacity = 0.0
        self.sceneView.scene.rootNode.addChildNode(textNode)
        textNode.position = coord
        let backNode = SCNNode()
        let plaque = SCNBox(width: 0.14, height: 0.1, length: 0.01, chamferRadius: 0.005)
        plaque.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 1.0)
        backNode.geometry = plaque
        backNode.position.y += 0.09
        
        
        
        //Set up card view
        let imageView = UIView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        imageView.backgroundColor = .clear
        imageView.alpha = 1.0
        imageView.layer.cornerRadius = 15
        let titleLabel = UILabel(frame: CGRect(x: 8, y: 64, width: imageView.frame.width, height: 100))
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont(name: "Avenir", size: 84)
        titleLabel.text = titleString.capitalized
        titleLabel.textColor = .black
        titleLabel.backgroundColor = .clear
        imageView.addSubview(titleLabel)
        
        let paragraphLabel = UILabel(frame: CGRect(x: 8, y: 160, width: imageView.frame.width, height: 100))
        paragraphLabel.textAlignment = .left
        paragraphLabel.numberOfLines = 9
        paragraphLabel.font = UIFont(name: "Avenir", size: 32)
        paragraphLabel.text = paragraphString
        paragraphLabel.textColor = .gray
        paragraphLabel.backgroundColor = .clear
        imageView.addSubview(paragraphLabel)
        
        
        let buttonNode = self.createButton(size: CGSize(width: imageView.frame.width - 128, height: 84))
        buttonNode.name = titleString + "C==3"
        
        self.buttons.append(buttonNode)
        
        let texture = UIImage.imageWithView(view: imageView)
        
        let infoNode = SCNNode()
        let infoGeometry = SCNPlane(width: 0.13, height: 0.09)
        infoGeometry.firstMaterial?.diffuse.contents = texture
        infoNode.geometry = infoGeometry
        infoNode.position.y += 0.09
        infoNode.position.z += 0.0055
        
        textNode.addChildNode(backNode)
        textNode.addChildNode(infoNode)
        
        infoNode.addChildNode(buttonNode)
        buttonNode.position = infoNode.position
        buttonNode.position.y -= (0.125)
        
        textNode.constraints = [billboardConstraint]
        textNode.runAction(SCNAction.scale(to: 0.0, duration: 0))
        backNode.runAction(SCNAction.scale(to: 0.0, duration: 0))
        infoNode.runAction(SCNAction.scale(to: 0.0, duration: 0))
        textNode.runAction(SCNAction.fadeOpacity(to: 0.0, duration: 0))
        backNode.runAction(SCNAction.fadeOpacity(to: 0.0, duration: 0))
        infoNode.runAction(SCNAction.fadeOpacity(to: 0.0, duration: 0))
        
        textNode.runAction(SCNAction.wait(duration: 0.01))
        backNode.runAction(SCNAction.wait(duration: 0.01))
        infoNode.runAction(SCNAction.wait(duration: 0.01))
        textNode.runAction(SCNAction.scale(to: 1.0, duration: 0.3) )
        backNode.runAction(SCNAction.scale(to: 1.0, duration: 0.3) )
        infoNode.runAction(SCNAction.scale(to: 1.0, duration: 0.3) )
        textNode.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 0.3))
        backNode.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 0.3))
        infoNode.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 0.3))
        self.nutrition.append(infoNode)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "arToWeb"){
            
            let dest = segue.destination as! WebViewController
            
            print("http://en.wikipedia.org/wiki/\(convertToURLable(string: urlEnd))")
            
            dest.urll = URL(string: "http://en.wikipedia.org/wiki/\(convertToURLable(string: urlEnd))")
            
            
            
        }
        
    }
    
}
