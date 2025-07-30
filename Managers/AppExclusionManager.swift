//
//  AppExclusionManager.swift
//  Archie
//
//  Created by Amy Elenius on 31/7/2025.
//


// AppExclusionManager.swift

import Foundation
import AppKit

// MARK: - App Exclusion Manager 100500
class AppExclusionManager: ObservableObject {
    static let shared = AppExclusionManager()
    
    @Published var excludedApps: Set<String> = [] {
        didSet {
            saveExcludedApps()
        }
    }
    
    private let excludedAppsKey = "excludedApps"
    
    private init() {
        loadExcludedApps()
    }
    
    // Check if the currently active app should be excluded
    func isCurrentAppExcluded() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        
        let bundleIdentifier = frontmostApp.bundleIdentifier ?? ""
        let appName = frontmostApp.localizedName ?? ""
        
        // Check both bundle identifier and app name
        return excludedApps.contains(bundleIdentifier) || excludedApps.contains(appName)
    }
    
    // Add app to exclusion list
    func addExcludedApp(_ appIdentifier: String) {
        excludedApps.insert(appIdentifier)
    }
    
    // Remove app from exclusion list
    func removeExcludedApp(_ appIdentifier: String) {
        excludedApps.remove(appIdentifier)
    }
    
    // Get list of currently running apps for selection
    func getRunningApps() -> [AppInfo] {
        let runningApps = NSWorkspace.shared.runningApplications
        
        return runningApps.compactMap { app in
            guard let bundleIdentifier = app.bundleIdentifier,
                  let appName = app.localizedName,
                  app.activationPolicy == .regular,
                  !bundleIdentifier.isEmpty,
                  !appName.isEmpty else {
                return nil
            }
            
            return AppInfo(
                name: appName,
                bundleIdentifier: bundleIdentifier,
                icon: app.icon
            )
        }
        .sorted { $0.name < $1.name }
    }
    
    // Get app info for excluded apps
    func getExcludedAppInfos() -> [AppInfo] {
        var appInfos: [AppInfo] = []
        
        for excludedApp in excludedApps {
            // Try to find app info
            if let runningApp = NSWorkspace.shared.runningApplications.first(where: { 
                $0.bundleIdentifier == excludedApp || $0.localizedName == excludedApp 
            }) {
                let appInfo = AppInfo(
                    name: runningApp.localizedName ?? excludedApp,
                    bundleIdentifier: runningApp.bundleIdentifier ?? excludedApp,
                    icon: runningApp.icon
                )
                appInfos.append(appInfo)
            } else {
                // App not currently running, create basic info
                let appInfo = AppInfo(
                    name: excludedApp,
                    bundleIdentifier: excludedApp,
                    icon: nil
                )
                appInfos.append(appInfo)
            }
        }
        
        return appInfos.sorted { $0.name < $1.name }
    }
}

// MARK: - Persistence 100501
extension AppExclusionManager {
    private func saveExcludedApps() {
        let excludedAppsArray = Array(excludedApps)
        UserDefaults.standard.set(excludedAppsArray, forKey: excludedAppsKey)
    }
    
    private func loadExcludedApps() {
        if let excludedAppsArray = UserDefaults.standard.array(forKey: excludedAppsKey) as? [String] {
            excludedApps = Set(excludedAppsArray)
        }
    }
}

// MARK: - App Info Model 100502
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let icon: NSImage?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}