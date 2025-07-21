// SoundManager.swift

import Foundation
import AppKit
import AudioToolbox

// MARK: - Sound Manager 100200
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private init() {}
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
        case basso = "Basso"
        case frog = "Frog"
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
            case .basso: return "Basso"
            case .frog: return "Frog"
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
        // Try to play using NSSound first
        if let sound = NSSound(named: soundName) {
            sound.volume = 0.5
            sound.play()
            print("DEBUG SOUND: Playing NSSound \(soundName)")
            return
        }
        
        // Try to find system sound file
        guard let soundURL = getSystemSoundURL(for: soundName) else {
            print("DEBUG SOUND: Could not find sound file for \(soundName)")
            playAlternativeSound()
            return
        }
        
        // Try to play using NSSound with URL
        if let sound = NSSound(contentsOf: soundURL, byReference: false) {
            sound.volume = 0.5
            sound.play()
            print("DEBUG SOUND: Playing sound from URL \(soundName)")
        } else {
            print("DEBUG SOUND: Failed to create NSSound from URL for \(soundName)")
            playAlternativeSound()
        }
    }
    
    private func getSystemSoundURL(for soundName: String) -> URL? {
        // Try common macOS system sound paths
        let possiblePaths = [
            "/System/Library/Sounds/\(soundName).aiff",
            "/System/Library/Sounds/\(soundName).wav",
            "/System/Library/Sounds/\(soundName).mp3",
            "/System/Library/Sounds/\(soundName).caf"
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
        // Fallback to system beep using AudioToolbox
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_UserPreferredAlert))
    }
    
    func previewSound(_ sound: ExpansionSound) {
        guard let systemSoundName = sound.systemSoundName else {
            playAlternativeSound()
            return
        }
        playSystemSound(named: systemSoundName)
    }
}
