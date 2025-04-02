//
//  MapView.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 4/1/25.
//


import SwiftUI
import MapKit

struct MapView: View {
    @Binding var cameraPosition: MapCameraPosition
    let chatt: Chatt?
    @State private var selected: Chatt?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selected) {
            if let chatt {
                if let geodata = chatt.geodata {
                    Marker(chatt.username!, systemImage: "figure.wave",
                           coordinate: CLLocationCoordinate2D(latitude: geodata.lat, longitude: geodata.lon))
                    .tint(.red)
                    .tag(chatt)
                }
            } else {
                ForEach(ChattStore.shared.chatts, id: \.self) { chatt in
                    if let geodata = chatt.geodata {
                        Marker(chatt.username!, systemImage: "figure.wave",
                               coordinate: CLLocationCoordinate2D(latitude: geodata.lat, longitude: geodata.lon))
                        .tint(.mint)
                    }
                }
            }
            if let chatt = selected, let geodata = chatt.geodata {
                Annotation(chatt.username!, coordinate: CLLocationCoordinate2D(latitude: geodata.lat, longitude: geodata.lon), anchor: .topLeading
                ) {
                    InfoView(chatt: chatt)
                }
                .annotationTitles(.hidden)
            }
            
            UserAnnotation() // shows user location
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}

struct InfoView: View {
    let chatt: Chatt
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let username = chatt.username, let timestamp = chatt.timestamp {
                    Text(username).padding(EdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 0)).font(.system(size: 16))
                    Spacer()
                    Text(timestamp).padding(EdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 4)).font(.system(size: 12))
                }
            }
            if let message = chatt.message {
                Text(message).padding(EdgeInsets(top: 1, leading: 8, bottom: 0, trailing: 4)).font(.system(size: 14)).lineLimit(2, reservesSpace: true)
            }
            if let geodata = chatt.geodata {
                Text("\(geodata.postedFrom)").padding(EdgeInsets(top: 0, leading: 8, bottom: 10, trailing: 4)).font(.system(size: 12)).lineLimit(2, reservesSpace: true)
            }
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .cornerRadius(4.0)
        }
        .frame(width: 300)
    }
}
