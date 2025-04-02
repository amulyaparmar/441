//
//  MainView.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar TYG  on 1/29/25.
//

import SwiftUI

struct MainView: View {
    private let store = ChattStore.shared
    @State private var isPresenting = false

    var body: some View {
        List(store.chatts) {
            ChattListRow(chatt: $0)
                .listRowSeparator(.hidden)
                .listRowBackground(Color($0.altRow ?
                    .systemGray5 : .systemGray6))
        }
        .listStyle(.plain)
        .refreshable {
            await store.getChatts()
        }
        .navigationTitle("Chatter")  
        .navigationBarTitleDisplayMode(.inline)          
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                Button { 
                    Task {
                        await ChatterID.shared.open()
                        isPresenting.toggle()
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .navigationDestination(isPresented: $isPresenting) {
            PostView(isPresented: $isPresenting)
        }          
    }
}

#Preview {
    MainView()
}
