//
//  PassGenApp.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import SwiftUI

@main
struct PassGenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
