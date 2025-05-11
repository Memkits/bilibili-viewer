//
//  ContentView.swift
//  bilibili-viewer
//
//  Created by chen on 2025/5/11.
//

import RealityKit
import RealityKitContent
import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @State private var currentURL: URL
    @State private var searchText: String = ""
    @State private var webView: WKWebView? = nil  // To control the WebView

    init() {
        let urlString = AppModel().bilibiliSearch4kStreetViewURL
        _currentURL = State(
            initialValue: URL(string: urlString) ?? URL(string: "https://www.bilibili.com")!)
    }

    private func performSearch() {
        if let encodedSearchText = searchText.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed),
            let searchURL = URL(
                string:
                    "\(appModel.bilibiliSearchURLBase)\(encodedSearchText)&from_source=webtop_search&spm_id_from=333.788&search_source=3"
            )
        {
            currentURL = searchURL
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()  // Add spacer at the beginning to push content to center

                Button {
                    webView?.goBack()
                } label: {
                    Label("Back", systemImage: "arrow.backward")
                }
                .disabled(!(webView?.canGoBack ?? false))

                TextField("Search on Bilibili", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                    .onSubmit {
                        performSearch()
                    }

                Button {
                    performSearch()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(searchText.isEmpty)

                Spacer()  // Add spacer at the end to push content to center
            }
            .padding()
            .background(.thinMaterial)

            WebView(url: $currentURL, currentWebViewInstance: $webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: webView?.canGoBack) { _, _ in
                    // This is a bit of a workaround to force the view to re-evaluate `canGoBack`
                    // A more robust solution might involve a custom Coordinator for the WebView
                    // that publishes canGoBack changes.
                    // For now, triggering a state change on currentURL (even to itself)
                    // or having a dedicated @State variable that gets toggled might work.
                    // Let's try a simpler approach first by just having the disabled state check it.
                    // The .disabled modifier should re-evaluate when the view updates.
                    // We might need to observe webView.canGoBack more directly if this isn't enough.
                }

            HStack {
                Spacer()  // Add spacer at the beginning to push content to center

                Button {
                    // Execute JavaScript to click the fullscreen button
                    if isBilibiliVideoPage(url: currentURL) {
                        triggerBilibiliFullscreen()
                    } else {
                        // Optionally, provide feedback that it's not a video page
                        print("Not a Bilibili video page or unable to trigger fullscreen.")
                    }
                } label: {
                    Label("Toggle Fullscreen", systemImage: "arrow.up.right.video.fill")
                }
                .disabled(!isBilibiliVideoPage(url: currentURL))

                Button {
                    if isBilibiliVideoPage(url: currentURL) {
                        triggerPlayPause()
                    }
                } label: {
                    Label("Play/Pause", systemImage: "playpause.fill")
                }
                .disabled(!isBilibiliVideoPage(url: currentURL))

                Spacer()  // Add spacer at the end to push content to center
            }
            .padding()
            .background(.thinMaterial)
        }
        .onChange(of: currentURL) { _, newURL in
            // This ensures that if the user navigates within the WebView,
            // the 'Toggle Fullscreen' button's state is updated.
            print("Current URL changed to: \(newURL)")
        }
    }

    // Helper function to check if the current URL is a Bilibili video page
    private func isBilibiliVideoPage(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains(appModel.bilibiliVideoHost)
            && url.path.starts(with: appModel.bilibiliVideoPathPrefix)
    }

    // Function to execute JavaScript for fullscreen
    private func triggerBilibiliFullscreen() {
        let script =
            "el = document.querySelector('.bpx-player-ctrl-web'); console.log('Inspect', el);  el.click();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution failed: \(error)")
            } else {
                print("JavaScript for fullscreen executed. Result: \(String(describing: result))")
            }
        }

    }

    private func triggerPlayPause() {
        let script = "document.querySelector('.bpx-player-ctrl-play')?.click();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution for play/pause failed: \(error)")
            } else {
                print("JavaScript for play/pause executed. Result: \(String(describing: result))")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
