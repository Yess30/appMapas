//
//  ViewController.swift
//  buscadorMapas
//
//  Created by Mac19 on 05/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var buscador: UISearchBar!
    @IBOutlet weak var mapa: MKMapView!
    
    var latitud: CLLocationDegrees!
    var longitud: CLLocationDegrees!
    var altitud: Double?
    var distKM: Double!
    var distString: String!
    
    //manager para el gps
    
    var manager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buscador.delegate = self
        manager.delegate = self
        
        mapa.delegate = self
        
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        //mejorar precision
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        
    }
    
    //trazar ruta
    
    func trazarRuta(coordenadasDest: CLLocationCoordinate2D){
        guard let coordOrigen = manager.location?.coordinate else {
            return
        }
        //Crear un lugar de origen - destino
        let oringen = MKPlacemark(coordinate: coordOrigen)
        let destino = MKPlacemark(coordinate: coordenadasDest)
        
        let or = CLLocation(latitude: coordOrigen.latitude, longitude: coordOrigen.longitude)
        let des = CLLocation(latitude: coordenadasDest.latitude, longitude: coordenadasDest.longitude)
        
        let distancia = or.distance(from: des)
        distKM = distancia/1000
        distString = String(format: "%.2f", distKM)
       
        
        //crear obje)to en mapkit
        let origenItem = MKMapItem(placemark: oringen)
        let destinoItem = MKMapItem(placemark: destino)
        
        //Solicitud de ruta
        
        let solicitudDest = MKDirections.Request()
        solicitudDest.source = origenItem
        solicitudDest.destination = destinoItem
        
        //Como se va a viajar
        solicitudDest.transportType = .automobile
        solicitudDest.requestsAlternateRoutes = true
        
        
        let direcciones = MKDirections(request: solicitudDest)
        direcciones.calculate {(respuesta, error) in
            //variable segura
            guard let respuestaSegura = respuesta else {
                if let error = error {
                    print("Error al calcular la ruta \(error.localizedDescription)")
                }
                return
            }
            
            //si todo salio bien
            print(respuestaSegura.routes.count)
            let ruta = respuestaSegura.routes[0]
            //agregar al mapa una superposicion
            
            self.mapa.addOverlay(ruta.polyline)
            self.mapa.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
            
            
        }
    }
    
    //Metodo de ayuda para agregar la superposicion al mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .cyan
        return renderizado
    }


    @IBAction func btnUbicacion(_ sender: UIBarButtonItem) {
        
        let alerta = UIAlertController(title: "Ubicacion", message: "Las coordenadas son: \n Latitud: \(latitud ?? 0) \n Longitud: \(longitud!) \n Altitud: \(altitud!)", preferredStyle: .alert)
        
        let acAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(acAceptar)
        
        present(alerta, animated: true)
        
        let localizacion = CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region = MKCoordinateRegion(center: localizacion, span: spanMapa)
        
        mapa.setRegion(region, animated: true)
        mapa.showsUserLocation = true
    }
}

extension ViewController: CLLocationManagerDelegate, UISearchBarDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("numero de ubicaciones \(locations.count)")
        
        guard let ubicacion = locations.first else{
            return
        }
        
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        
        altitud = ubicacion.altitude
        
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicacion \(error.localizedDescription)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Ubicacion encontrada!")
        
        //Ocultar teclado
        buscador.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        if let direccion = buscador.text{
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                
                
                //crear destino
                guard let destinoRuta = places?.first?.location else {
                    return
                }
                
                
                
                
                if error == nil {
                    //buscar direccion
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    
                    let regiom = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.mapa.setRegion(regiom, animated: true)
                    self.mapa.addAnnotation(anotacion)
                    self.mapa.selectAnnotation(anotacion, animated: true)
                    
                    //mandar llamar a trazar ruta
                    self.trazarRuta(coordenadasDest: destinoRuta.coordinate)
                    
                    let alerta = UIAlertController(title: "Distancia", message: "Las Distancia entre los puntos es: \(self.distString ?? "")", preferredStyle: .alert)
                    
                    let acAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                    
                    alerta.addAction(acAceptar)

                    self.present(alerta, animated: true)
                     
                     
                }else{
                    print("Error al encontrar la direccion")
                }
            }
        }
    }
    
}
