//
//  swiftUIChatterApp.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//

import SwiftUI

@main
struct swiftUIChatterApp: App {
    init() {
        ChattStore.shared.getChatts()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
            }
        }
    }
}
