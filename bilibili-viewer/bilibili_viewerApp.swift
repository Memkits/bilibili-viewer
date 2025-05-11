//
//  bilibili_viewerApp.swift
//  bilibili-viewer
//
//  Created by chen on 2025/5/11.
//

import SwiftUI
import WebKit  // Add this import

@main
struct bilibili_viewerApp: App {
    @StateObject private var appModel = AppModel()  // Changed from @StateObject
    @State private var mainWebView: WKWebView? = nil
    @State private var playerWebView: WKWebView? = nil

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            ContentView()  // Ensure ContentView is called without arguments
                .environment(appModel)  // Added environment modifier
        }

        WindowGroup(id: "videoPlayerWindow") {  // Corrected WindowGroup usage
            // Ensure you have a view here that uses the playerWebView
            // For example, a dedicated PlayerView or reuse WebView
            // If reusing WebView, it needs to be adapted or a new instance created
            // For now, let's assume a simple placeholder or a correctly configured WebView
            Group {  // Wrap conditional content in a Group to apply environment modifier
                if let playerURL = appModel.videoPlayerURL {
                    WebView(url: .constant(playerURL), currentWebViewInstance: $playerWebView)
                } else {
                    Text("No video to play")  // Placeholder
                }
            }
            .environment(appModel)  // Added environment modifier
        }
        .windowStyle(.volumetric)  // Example of how you might style a media player window
        // To control presentation, you would typically use .openWindow or .dismissWindow actions
        // triggered by changes in appModel.showVideoPlayerWindow, rather than binding it directly here.
        // For example, in ContentView or another relevant view:
        // .onChange(of: appModel.showVideoPlayerWindow) { newValue in
        //     if newValue {
        //         openWindow(id: "videoPlayerWindow")
        //     } else {
        //         dismissWindow(id: "videoPlayerWindow")
        //     }
        // }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(appModel)  // Added environment modifier
        }
    }
}
