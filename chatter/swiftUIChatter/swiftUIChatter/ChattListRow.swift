//
//  ChattListRow.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import SwiftUI

struct ChattListRow: View {
    let chatt: Chatt
    @Environment(AudioPlayer.self) private var audioPlayer
    @State private var isPresenting = false
    
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
                if let message = chatt.message {
                    Text(message).padding(EdgeInsets(top: 8, leading: 0, bottom: 6, trailing: 0))
                }
                Spacer()
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
