//
//  GeoData.swift.swift
//  swiftUIChatter
//
//  Created by Gideon Shaked on 4/1/25.
//

import MapKit

struct GeoData: Hashable {
    var lat: Double = 0.0
    var lon: Double = 0.0
    var place: String = ""
    var facing: String = "unknown"
    var speed: String = "unknown"
    
    mutating func setPlace() async {
        let geolocs = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon))
        if let geolocs {
            place = geolocs[0].locality ?? geolocs[0].administrativeArea ?? geolocs[0].country ?? "Place unknown"
        } else {
            place = "Place unknown"
        }
    }
    
    var postedFrom: AttributedString {
        var posted = try! AttributedString(markdown: "Posted from **\(place)** while facing **\(facing)** moving at **\(speed)** speed.")
        ["\(place)", "\(facing)", "\(speed)"].forEach {
            if !$0.isEmpty {
                posted[posted.range(of: $0)!].foregroundColor = .blue
            }
        }
        return posted
    }
}
