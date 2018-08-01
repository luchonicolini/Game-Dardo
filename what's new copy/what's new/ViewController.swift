//
//  ViewController.swift
//  what's new
//
//  Created by luciano on 27/07/2018.
//  Copyright © 2018 nicolini.com. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import CoreLocation
import GameplayKit

class ViewController: UIViewController, ARSKViewDelegate,
CLLocationManagerDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    
    //1 se encarga mandar sms a la app para saber donde esta el usuario
    let locationManger = CLLocationManager()
    var userLocation = CLLocation()
    
    var sitesJSON: JSON!
    //direccion donde mira el usuario
    var userHeding = 0.0
    var hedingStep = 0
    
    var sites = [UUID:String]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //2nos estara mandando info costante
        locationManger.delegate = self
        //para que sea super precisa ! alerta consume mucha bateria
        locationManger.desiredAccuracy = kCLLocationAccuracyBest
        //solo cuando este en uso; al acceder a la ubicacion
        locationManger.requestWhenInUseAuthorization()
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = false
        sceneView.showsNodeCount = false
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = AROrientationTrackingConfiguration()
        // Run the view's session // se debe modificar
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSKViewDelegate
    //LA PARTE VISUAL -> CAMARA
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
       let labelNode = SKLabelNode(text: sites[anchor.identifier])
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        
        //config
        let newSize = labelNode.frame.size.applying(CGAffineTransform(scaleX: 1.1, y: 1.5))
        
        let backgroundNode = SKShapeNode(rectOf: newSize, cornerRadius: 10)
        let randomColor = UIColor(hue: CGFloat(GKRandomSource.sharedRandom().nextUniform()), saturation: 0.5, brightness: 0.4, alpha: 0.9)
        
        backgroundNode.strokeColor = randomColor.withAlphaComponent(1.0)
        backgroundNode.lineWidth = 2
        
        backgroundNode.addChild(labelNode)
      
        return backgroundNode
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
    
    //MARCK: locationMangger
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManger.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        userLocation = location

        DispatchQueue.global().async {
            self.updateSite()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.hedingStep += 1
            if self.hedingStep < 2 {return}
            self.userHeding = newHeading.magneticHeading
            self.locationManger.stopUpdatingHeading()
            
        
            
        }
    }
    
    func updateSite() {
        let urlString = "https://es.wikipedia.org/w/api.php?ggscoord=\(userLocation.coordinate.latitude)%7C\(userLocation.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        
        guard let url = URL(string: urlString) else {return}
        if let data = try? Data(contentsOf: url) {
            sitesJSON = JSON(data)
            //la  direccion donde aputa el usuario
            locationManger.stopUpdatingHeading()
        }
     
        func createSite() {
            for page in sitesJSON["query"]["pages"].dictionaryValue.values {
               //
                let lat = page["coordinates"][0]["lat"].doubleValue
                let lon = page["coordinates"][0]["lon"].doubleValue
                let location = CLLocation(latitude: lat, longitude: lon)
                //
                let distance = Float(userLocation.distance(from: location))
                let azimud  = direction(from: userLocation, to: location)
                //
                let angle = azimud - userHeding
                let angleRad = deg2rad(angle)
                //SCNmakeTO LE CAMBIE NO ES LA MISMA -> POR float4x4.init(....)
                let horizontalRotation = float4x4.init(SCNMatrix4MakeRotation(Float(angleRad), 1, 0, 0))
                //
                let verticalRotation = float4x4.init(SCNMatrix4MakeRotation(-0.3 + Float(distance/500), 0, 1, 0))
                //
                let rotation = simd_mul(horizontalRotation, verticalRotation)
                
                guard let sceneView = self.view as? ARSKView else { return }
                guard let currenFrame = sceneView.session.currentFrame else { return }
                let rotation2 = simd_mul(currenFrame.camera.transform, rotation)
                var traslation = matrix_identity_float4x4
                traslation.columns.3.z = -(distance / 10000)
                
                let transform = simd_mul(rotation2, traslation)
                let anchor = ARAnchor(transform: transform)
                sceneView.session.add(anchor: anchor)
            //Distancia
                sites[anchor.identifier] = "\(page["title"].string ?? "Unknow place.") - \(distance / 1000) km"
                
                
            }
            
        }
        
        //Retocar la distancia minima y maxima
        func clamp(value: Float, minValue: Float, maxValue: Float) -> Float {
            return min(max(value, minValue), maxValue)
        }
        
        //MARCK: Matematicas
        func deg2rad(_ degrees:Double) -> Double {
            return degrees * Double.pi / 180.0
        }
        func rad2deg(_ radians:Double) -> Double {
            return radians * 180.0 / Double.pi
        }
        //
        func direction(from p1:CLLocation, to p2:CLLocation) -> Double {
            let dif_long = p2.coordinate.longitude - p1.coordinate.longitude
           
            let y = sin(dif_long) * cos(p2.coordinate.longitude)
            let x = cos(p1.coordinate.latitude) * cos(p2.coordinate.latitude) - sin(p1.coordinate.latitude) * cos(p2.coordinate.latitude) * cos(dif_long)
            let atan_rad = atan2(y, x)
            
            return rad2deg(atan_rad)
            
        }
    }
    
}



