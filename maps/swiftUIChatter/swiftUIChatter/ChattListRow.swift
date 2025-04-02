//
//  ChattListRow.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import SwiftUI
import MapKit

struct ChattListRow: View {
    let chatt: Chatt
    var displayChatt: ((Chatt) -> Void)? = nil
    @Binding var cameraPosition: MapCameraPosition
    
    @Environment(AudioPlayer.self) private var audioPlayer
    @State private var isPresenting = false
    
    // This is needed to create a default binding for previews and testing
    init(chatt: Chatt, displayChatt: ((Chatt) -> Void)? = nil, cameraPosition: Binding<MapCameraPosition>? = nil) {
        self.chatt = chatt
        self.displayChatt = displayChatt
        self._cameraPosition = cameraPosition ?? .constant(.automatic)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let username = chatt.username, let timestamp = chatt.timestamp {
                    Text(username).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                    Spacer()
                    Text(timestamp).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    if let message = chatt.message {
                        Text(message).padding(EdgeInsets(top: 8, leading: 0, bottom: 6, trailing: 0))
                    }
                    if let geodata = chatt.geodata {
                        Text(geodata.postedFrom).padding(EdgeInsets(top: 8, leading: 0, bottom: 6, trailing: 0)).font(.system(size: 14))
                    }
                }
                Spacer()
                if chatt.geodata != nil {
                    Button {
                        if let displayChatt = displayChatt {
                            if let geodata = chatt.geodata {
                                cameraPosition = .camera(MapCamera(
                                    centerCoordinate: CLLocationCoordinate2D(latitude: geodata.lat, longitude: geodata.lon),
                                    distance: 500, heading: 0, pitch: 60))
                            }
                            displayChatt(chatt)
                        }
                    } label: {
                        Image(systemName: "mappin.and.ellipse").scaleEffect(1.5)
                    }
                }
                if let audio = chatt.audio {
                    Button {
                        audioPlayer.setupPlayer(audio)
                        isPresenting.toggle()
                    } label: {
                        Image(systemName: "recordingtape").scaleEffect(1.5)
                    }
                    .fullScreenCover(isPresented: $isPresenting) {
                        AudioView(isPresented: $isPresenting, autoPlay: true)
                    }
                }
            }
        }
    }
}
