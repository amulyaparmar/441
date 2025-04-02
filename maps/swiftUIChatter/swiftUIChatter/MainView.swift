//
//  MainView.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar TYG  on 1/29/25.
//

import SwiftUI
import MapKit

struct MainView: View {
    private let store = ChattStore.shared
    @State private var isPresenting = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selected: Chatt?
    @State private var isMapping = false

    var body: some View {
        List(store.chatts) {
            ChattListRow(chatt: $0, displayChatt: displayChatt, cameraPosition: $cameraPosition)
                .listRowSeparator(.hidden)
                .listRowBackground(Color($0.altRow ?
                    .systemGray5 : .systemGray6))
        }
        .listStyle(.plain)
        .refreshable {
            store.getChatts()
        }
        .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
            .onEnded { value in
                if case (...0, -100...100) = (value.translation.width, value.translation.height) {
                    cameraPosition = .camera(MapCamera(
                       centerCoordinate: CLLocationCoordinate2D(latitude: LocManager.shared.location.coordinate.latitude, longitude: LocManager.shared.location.coordinate.longitude), distance: 500, heading: 0, pitch: 60))
                    isMapping.toggle()
                }
            }
        )
        .navigationDestination(isPresented: $isMapping) {
            MapView(cameraPosition: $cameraPosition, chatt: selected)
        }
        .onAppear {
            selected = nil
        }
        .navigationTitle("Chatter")  
        .navigationBarTitleDisplayMode(.inline)          
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                Button { 
                    isPresenting.toggle() 
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .navigationDestination(isPresented: $isPresenting) {
            PostView(isPresented: $isPresenting)
        }          
    }
    
    func displayChatt(chatt: Chatt) {
        selected = chatt
        isMapping = true
    }
}

#Preview {
    MainView()
}
