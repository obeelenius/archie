//
//  SoundManager.swift
//  Archie
//
//  Created by Amy Elenius on 21/7/2025.
//


// SoundManager.swift

import Foundation
import AVFoundation

// MARK: - Sound Manager 100200
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("DEBUG SOUND: Failed to setup audio session: \(error)")
        }
    }
}

// MARK: - Available Sounds 100201
extension SoundManager {
    enum ExpansionSound: String, CaseIterable {
        case pop = "Pop"
        case glass = "Glass"
        case hero = "Hero"
        case tink = "Tink"
        case blow = "Blow"
        case bottle = "Bottle"
        case funk = "Funk"
        case morse = "Morse"
        case ping = "Ping"
        case purr = "Purr"
        case sosumi = "Sosumi"
        case submarine = "Submarine"
        case none = "None"
        
        var displayName: String {
            return self.rawValue
        }
        
        var systemSoundName: String? {
            switch self {
            case .pop: return "Pop"
            case .glass: return "Glass"
            case .hero: return "Hero"
            case .tink: return "Tink"
            case .blow: return "Blow"
            case .bottle: return "Bottle"
            case .funk: return "Funk"
            case .morse: return "Morse"
            case .ping: return "Ping"
            case .purr: return "Purr"
            case .sosumi: return "Sosumi"
            case .submarine: return "Submarine"
            case .none: return nil
            }
        }
    }
}

// MARK: - Sound Playback 100202
extension SoundManager {
    func playExpansionSound() {
        // Check if sound is enabled
        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        guard soundEnabled else { return }
        
        // Get selected sound
        let selectedSoundRaw = UserDefaults.standard.string(forKey: "selectedExpansionSound") ?? ExpansionSound.pop.rawValue
        let selectedSound = ExpansionSound(rawValue: selectedSoundRaw) ?? .pop
        
        guard let systemSoundName = selectedSound.systemSoundName else { return }
        
        playSystemSound(named: systemSoundName)
    }
    
    private func playSystemSound(named soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "aiff", subdirectory: "System/Library/Sounds") ??
              Bundle.main.url(forResource: soundName, withExtension: "aiff") ??
              getSystemSoundURL(for: soundName) else {
            print("DEBUG SOUND: Could not find sound file for \(soundName)")
            playAlternativeSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
            print("DEBUG SOUND: Playing sound \(soundName)")
        } catch {
            print("DEBUG SOUND: Error playing sound \(soundName): \(error)")
            playAlternativeSound()
        }
    }
    
    private func getSystemSoundURL(for soundName: String) -> URL? {
        // Try common macOS system sound paths
        let possiblePaths = [
            "/System/Library/Sounds/\(soundName).aiff",
            "/System/Library/Sounds/\(soundName).wav",
            "/System/Library/Sounds/\(soundName).mp3"
        ]
        
        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
    
    private func playAlternativeSound() {
        // Fallback to system beep
        NSSound.beep()
    }
    
    func previewSound(_ sound: ExpansionSound) {
        guard let systemSoundName = sound.systemSoundName else { return }
        playSystemSound(named: systemSoundName)
    }
}