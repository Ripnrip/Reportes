/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase


struct Sighting {
  
  let ref: FIRDatabaseReference?
  let lat:Double
  let long:Double
  let type:String
  
  init(lat: Double, long: Double, type:String) {
    self.lat = long
    self.long = long
    self.type = type
    self.ref = nil
  }
  
  init(snapshot: FIRDataSnapshot) {
    let snapshotValue = snapshot.value as! [String: AnyObject]
    self.lat = snapshotValue["lat"] as! Double
    self.long = snapshotValue["long"] as! Double
    self.type = snapshotValue["type"] as! String
    ref = snapshot.ref
  }
  
  func toAnyObject() -> Any {
    return [
//      "name": name,
//      "addedByUser": addedByUser,
//      "completed": completed
    ]
  }
  
}
class MapViewController: UIViewController, UIActionSheetDelegate {

  
  @IBOutlet var map: MKMapView!
  @IBOutlet weak var mapView: MKMapView!
  var targets = [ARItem]()
  let locationManager = CLLocationManager()
  var userLocation: CLLocation?
  var selectedAnnotation: MKAnnotation?

  var locManager = CLLocationManager()
  var currentLocation: CLLocation!
  
  var locations:[Sighting] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    map.delegate = self
    mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    
    if CLLocationManager.authorizationStatus() == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()

    }
    let ref = FIRDatabase.database().reference()

    ref.observe(.value, with: { snapshot in
//      print(snapshot.value)
      for item in snapshot.children {
        let sighting = Sighting(snapshot: item as! FIRDataSnapshot)
        self.locations.append(sighting)
        print("the locations are \(sighting)")
        let annotation = MKPointAnnotation()
//        MKPointAnnotation.
        annotation.coordinate = CLLocationCoordinate2D(latitude: sighting.lat, longitude: sighting.long)
        annotation.title = sighting.type
        self.map.addAnnotation(annotation)
      }
    })
    
    print("the locations are \(locations)")

    
    //make array of points, then add to map
    
    //setupLocations()

    locManager.requestWhenInUseAuthorization()
    
    if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
      CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
      currentLocation = locManager.location
      print(currentLocation.coordinate.latitude)
      print(currentLocation.coordinate.longitude)
      
    }
  }
  

  func setupLocations() {
    let firstTarget = ARItem(itemDescription: "tacos", location: CLLocation(latitude: 50.5184, longitude: 8.3902), itemNode: nil)
    targets.append(firstTarget)
    
    let secondTarget = ARItem(itemDescription: "wolf", location: CLLocation(latitude: 50.5184, longitude: 8.3895), itemNode: nil)
    targets.append(secondTarget)
    
    let thirdTarget = ARItem(itemDescription: "dragon", location: CLLocation(latitude: 41.388004, longitude: 2.11328), itemNode: nil)
    targets.append(thirdTarget)
    
    for item in targets {
      let annotation = MapAnnotation(location: item.location.coordinate, item: item)
      self.mapView.addAnnotation(annotation)
    }
  }
  @IBAction func addLocationHere(_ sender: Any) {
    var ref = FIRDatabase.database().reference()
    var userId = UIDevice.current.identifierForVendor!.uuidString
    var sightingRef = ref.child(userId)
    var sightingType = ""
    //ask user for danger type
    let alert = UIAlertController(title: nil , message: "Please Select an Option", preferredStyle: .actionSheet)
    
    alert.addAction(UIAlertAction(title: "I need help", style: .default , handler:{ (UIAlertAction)in
      sightingType = "help"
      let sighting: [String: AnyObject] = ["lat":self.currentLocation.coordinate.latitude as AnyObject,"long":self.currentLocation.coordinate.longitude as AnyObject, "type":sightingType as AnyObject]
      sightingRef.setValue(sighting)
      //add pin to coordinate
      let annotation = MKPointAnnotation()
      annotation.title = "help"
      
      annotation.coordinate = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
      self.map.addAnnotation(annotation)
      
    }))
    
    alert.addAction(UIAlertAction(title: "Danger here", style: .default , handler:{ (UIAlertAction)in
      sightingType = "danger"
      let sighting: [String: AnyObject] = ["lat":self.currentLocation.coordinate.latitude as AnyObject,"long":self.currentLocation.coordinate.longitude as AnyObject, "type":sightingType as AnyObject]
      sightingRef.setValue(sighting)
      //add pin to coordinate
      let annotation = MKPointAnnotation()
      annotation.title = "danger"

      annotation.coordinate = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
      self.map.addAnnotation(annotation)
    }))
    
    alert.addAction(UIAlertAction(title: "Safe point", style: .default , handler:{ (UIAlertAction)in
      sightingType = "safe"
      let sighting: [String: AnyObject] = ["lat":self.currentLocation.coordinate.latitude as AnyObject,"long":self.currentLocation.coordinate.longitude as AnyObject, "type":sightingType as AnyObject]
      sightingRef.setValue(sighting)
      //add pin to coordinate
      let annotation = MKPointAnnotation()
      annotation.title = "safe"
      
      annotation.coordinate = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
      self.map.addAnnotation(annotation)
      
    }))
    
    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler:{ (UIAlertAction)in
      print("User click Dismiss button")
    }))
    
    self.present(alert, animated: true, completion: {
      print("completion block")


    })
    
  }
  
}


extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    self.userLocation = userLocation.location
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    let annotationView = MKPinAnnotationView()

      print("Pin Color Set \(annotation.title ?? "")")
    
    if annotation.title ?? "" ==  "safe" {
      annotationView.pinTintColor = UIColor.green
    }else if annotation.title ?? "" == "danger" {
      annotationView.pinTintColor = UIColor.red
    }else if annotation.title ?? "" == "help" {
      annotationView.pinTintColor = UIColor.blue
    }
    
    
    
    
    return annotationView
  }

  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    let coordinate = view.annotation!.coordinate
    
    print("just touched the pin")
    
    if let userCoordinate = userLocation {
      if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) < 50 {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ViewController {
          
          viewController.delegate = self
          
          if let mapAnnotation = view.annotation as? MapAnnotation {
            
            viewController.target = mapAnnotation.item
            viewController.userLocation = mapView.userLocation.location!
            selectedAnnotation = view.annotation
            self.present(viewController, animated: true, completion: nil)
          }
        }
      }
    }
  }
}

extension MapViewController: ViewControllerDelegate {
  func viewController(controller: ViewController, tappedTarget: ARItem) {
    self.dismiss(animated: true, completion: nil)
    let index = self.targets.index(where: {$0.itemDescription == tappedTarget.itemDescription})
    self.targets.remove(at: index!)
    
    if selectedAnnotation != nil {
      mapView.removeAnnotation(selectedAnnotation!)
    }
  }
}
