//
//  YinTimerApp.swift
//  YinTimer
//
//  Created by Anders Hovmöller on 2020-07-11.
//

import SwiftUI

@main
struct YinTimerApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { (phase) in
            switch phase {
            case .active:
                // In iOS 13+, idle timer needs to be set in scene to override default
                UIApplication.shared.isIdleTimerDisabled = true
            case .inactive: break
            case .background: break
            @unknown default: print("ScenePhase: unexpected state")
            }
        }
    }
}
