//
//  AudioView.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 2/11/25.
//


import SwiftUI
import Observation

@Observable
final class PlayerUIState {

    @ObservationIgnored var recHidden = false
    var recDisabled = false
    var recColor = Color(.systemBlue)
    var recIcon = Image(systemName: "largecircle.fill.circle") // initial value

    var playCtlDisabled = true

    var playDisabled = true
    var playIcon = Image(systemName: "play")

    var doneDisabled = false
    var doneIcon = Image(systemName: "square.and.arrow.up") // initial value
 
    private func reset() {
        recHidden = false
        recDisabled = false
        recColor = Color(.systemBlue)
        recIcon = Image(systemName: "largecircle.fill.circle") // initial value

        playCtlDisabled = true

        playDisabled = true
        playIcon = Image(systemName: "play")

        doneDisabled = false
        doneIcon = Image(systemName: "square.and.arrow.up") // initial value

    }
    
    private func playCtlEnabled(_ enabled: Bool) {
        playCtlDisabled = !enabled
    }
    
    private func playEnabled(_ enabled: Bool) {
        playIcon = Image(systemName: "play")
        playDisabled = !enabled
    }
    
    private func pauseEnabled(_ enabled: Bool) {
        playIcon = Image(systemName: "pause")
        playDisabled = !enabled
    }
    
    private func recEnabled() {
        recIcon = Image(systemName: "largecircle.fill.circle")
        recDisabled = false
        recColor = Color(.systemBlue)
    }
    
    func propagate(_ playerState: PlayerState) {
        switch (playerState) {
        case .start(.play):
            recHidden = true
            playEnabled(true)
            playCtlEnabled(false)
            doneIcon = Image(systemName: "xmark.square")
        case .start(.standby):
            if !recHidden { recEnabled() }
            playEnabled(true)
            playCtlEnabled(false)
            doneDisabled = false
        case .start(.record):
            // initial values already set up for record start mode.
            reset()
        case .recording:
            recIcon = Image(systemName: "stop.circle")
            recColor = Color(.systemRed)
            playEnabled(false)
            playCtlEnabled(false)
            doneDisabled = true
        case .paused:
            if !recHidden { recEnabled() }
            playIcon = Image(systemName: "play")
        case .playing:
            if !recHidden {
                recDisabled = true
                recColor = Color(.systemGray6)
            }
            pauseEnabled(true)
            playCtlEnabled(true)
        }
    }
}

struct RecButton: View {
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        let playerUIState = audioPlayer.playerUIState

        Button {
            audioPlayer.recTapped()
        } label: {
            playerUIState.recIcon
                .scaleEffect(3.5)
                .padding(.bottom, 80)
                .foregroundColor(playerUIState.recColor)
        }
        .disabled(playerUIState.recDisabled)
        .opacity(playerUIState.recHidden ? 0 : 1)
    }
}

struct DoneButton: View {
    @Binding var isPresented: Bool
    @Environment(AudioPlayer.self) private var audioPlayer
    
    var body: some View {
        let playerUIState = audioPlayer.playerUIState

        Button {
            audioPlayer.doneTapped()
            isPresented.toggle()
        } label: {
            playerUIState.doneIcon.scaleEffect(2.0)
        }
        .disabled(playerUIState.doneDisabled)
    }
}

struct PlayButton: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    
    var body: some View {
        let playerUIState = audioPlayer.playerUIState
        
        Button {
            audioPlayer.playTapped()
        } label: {
            playerUIState.playIcon.scaleEffect(2.0)
        }
        .disabled(playerUIState.playDisabled)
    }
}

struct StopButton: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    
    var body: some View {
        let playerUIState = audioPlayer.playerUIState
        
        Button {
            audioPlayer.stopTapped()
        } label: {
            Image(systemName: "stop").scaleEffect(2.0)
        }
        .disabled(playerUIState.playCtlDisabled)
    }
}

struct RwndButton: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    
    var body: some View {
        let playerUIState = audioPlayer.playerUIState
        
        Button {
            audioPlayer.rwndTapped()
        } label: {
            Image(systemName: "gobackward.10").scaleEffect(2.0)
        }
        .disabled(playerUIState.playCtlDisabled)
    }
}

struct FfwdButton: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    
    var body: some View {
        let playerUIState = audioPlayer.playerUIState
        
        Button {
            audioPlayer.ffwdTapped()
        } label: {
            Image(systemName: "goforward.10").scaleEffect(2.0)
        }
        .disabled(playerUIState.playCtlDisabled)
    }
}

struct AudioView: View {
    @Binding var isPresented: Bool
    var autoPlay = false
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                StopButton()
                Spacer()
                RwndButton()
                Spacer()
                PlayButton()
                Spacer()
                FfwdButton()
                Spacer()
                DoneButton(isPresented: $isPresented)
                Spacer()
            }
            Spacer()
            RecButton()
        }
        .onAppear {
            if autoPlay {
                audioPlayer.playTapped()
            }
        }
        .onDisappear {
            audioPlayer.doneTapped()
        }
    }
}
