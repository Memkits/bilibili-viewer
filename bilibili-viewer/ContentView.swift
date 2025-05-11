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
        _currentURL = State(initialValue: AppModel().bilibiliHomeURL)
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
                Button {
                    currentURL = appModel.bilibiliHomeURL
                } label: {
                    Label("Home", systemImage: "house.fill")
                }

                Button {
                    // Execute JavaScript to click the fullscreen button
                    if isBilibiliVideoPage(url: currentURL) {
                        triggerBilibiliFullscreen()
                    } else {
                        // Optionally, provide feedback that it's not a video page
                        print("Not a Bilibili video page or unable to trigger fullscreen.")
                    }
                } label: {
                    Label("Toggle Fullscreen", systemImage: "arrow.up.right.video.fill")  // Icon can remain similar
                }
                .disabled(!isBilibiliVideoPage(url: currentURL))  // Enable only on video pages

                Spacer()

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

            }
            .padding()
            .background(.thinMaterial)

            WebView(url: $currentURL, currentWebViewInstance: $webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
