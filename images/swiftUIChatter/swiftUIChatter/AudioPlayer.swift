//
//  StartMode.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 2/11/25.
//


import AVFoundation
import Observation

enum StartMode {
    case standby, record, play
}
enum PlayerState: Equatable {
    case start(StartMode)
    case recording
    case playing(StartMode)
    case paused(StartMode)
}

enum TransEvent {
    case recTapped, playTapped, stopTapped, doneTapped, failed
}

extension PlayerState {
    mutating func transition(_ event: TransEvent) {
        if (event == .doneTapped) {
            self = .start(.standby)
            return
        }        
        switch self {
        case .start(.record) where event == .recTapped:
            self = .recording
        case .start(.play) where event == .playTapped:
            self = .playing(.play)
        case .start(.standby):
            switch event {
            case .recTapped:
                self = .recording
            case .playTapped:
                self = .playing(.standby)
            default:
                break
            }
        case .recording:
            switch event {
            case .recTapped:
                fallthrough                
            case .stopTapped:
                self = .start(.standby)
            case .failed:
                self = .start(.record)
            default:
                break
            }
        case .playing(let parent):
            switch event {
            case .playTapped:
                self = .paused(parent)
            case .stopTapped, .failed:
                self = .start(parent)
            default:
                break
            }
        case .paused(let grand):
            switch event {
            case .recTapped:
                self = .recording
            case .playTapped:
                self = .playing(grand)
            case .stopTapped:
                self = .start(.standby)
            default:
                break
            }
        default:
            break
        }
    }
}

@Observable
final class AudioPlayer: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var audio: Data! = nil
    private let audioFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("chatteraudio.m4a")
    
    @ObservationIgnored let playerUIState = PlayerUIState()
    @ObservationIgnored var playerState = PlayerState.start(.standby) {
        didSet { playerUIState.propagate(playerState) }
    }
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder! = nil
    private var audioPlayer: AVAudioPlayer! = nil

    override init() {
        super.init()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("AudioPlayer: failed to setup AVAudioSession")
        }
    }

    func setupRecorder() {
        playerState = .start(.record)
        audio = nil
        
        guard let _ = audioRecorder else {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try? AVAudioRecorder(url: audioFilePath, settings: settings)
            guard let _ = audioRecorder else {
                print("setupRecorder: failed")
                return
            }
            audioRecorder.delegate = self
            return
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error encoding audio: \(error!.localizedDescription)")
        audioRecorder.stop()
        playerState.transition(.failed)
    }

    func setupPlayer(_ audioStr: String) {
        playerState = .start(.play)
        audio = Data(base64Encoded: audioStr, options: .ignoreUnknownCharacters)
        preparePlayer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error decoding audio \(error?.localizedDescription ?? "on playback")")
        // don't dismiss, in case user wants to record
        playerState.transition(.failed)
    }

    private func preparePlayer() {
        audioPlayer = try? AVAudioPlayer(data: audio)
        guard let audioPlayer else {
            print("preparePlayer: incompatible audio encoding, not m4a?")
            return
        }
        audioPlayer.volume = 10.0
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState.transition(.stopTapped)
    }

    func playTapped() {
        guard let audioPlayer else {
            print("playTapped: no audioPlayer!")
            return
        }
        playerState.transition(.playTapped)
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }

    func rwndTapped() {
        audioPlayer.currentTime = max(0, audioPlayer.currentTime - 10.0) // seconds
    }

    func ffwdTapped() {
        audioPlayer.currentTime = min(audioPlayer.duration, audioPlayer.currentTime + 10.0) // seconds
    }

    func stopTapped() {
        guard let audioPlayer else {
            print("stopTapped: no audioPlayer!")
            return
        }
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        playerState.transition(.stopTapped)
    }

    func recTapped() {
        if playerState == .recording {
            audioRecorder.stop()
            audio = try? Data(contentsOf: audioFilePath)
            preparePlayer()
        } else {
            audioRecorder.record()
        }
        playerState.transition(.recTapped)
    }

    func doneTapped() {
        defer {
            if let _ = audio {
                playerState.transition(.doneTapped)
            }
        }
                
        if let _ = audioPlayer {
            stopTapped()
        }
        
        guard let audioRecorder else {
            return
        }
        if playerState == .recording {
            recTapped()
        }
        audioRecorder.deleteRecording()  // clean up
    }
}