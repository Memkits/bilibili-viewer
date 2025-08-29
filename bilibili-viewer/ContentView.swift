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

            WebView(url: $currentURL, currentWebViewInstance: $webView) {
                finishedURL in
                // Check if it's a video page and trigger fullscreen
                if isBilibiliVideoPage(url: finishedURL) {
                    // Delay slightly to ensure the page elements are available
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  // 1 second delay
                        print("Attempting to trigger fullscreen for video page: \(finishedURL)")
                        let ret = triggerBilibiliFullscreen()

                        if !ret {
                            // another 2 seconds delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                let ret = triggerBilibiliFullscreen()

                                if !ret {
                                    print("Failed to trigger fullscreen again.")
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: webView?.canGoBack) { _, _ in
                print("WebView canGoBack changed: \(webView?.canGoBack ?? false)")
            }

            HStack {
                Spacer()  // Add spacer at the beginning to push content to center

                Button {
                    print("currentURL: \(currentURL)")
                    // Execute JavaScript to click the fullscreen button
                    if isBilibiliVideoPage(url: currentURL) {
                        let _ = triggerBilibiliFullscreen()
                    } else if isBilibiliBangumiPage(url: currentURL) {
                        let _ = triggerBilibiliBangumiFullscreen()
                    } else {
                        // Optionally, provide feedback that it's not a video page
                        print("Not a Bilibili video page or unable to trigger fullscreen.")
                    }
                } label: {
                    Label("Toggle Fullscreen", systemImage: "arrow.up.right.video.fill")
                }
                .disabled(
                    !isBilibiliVideoPage(url: currentURL) && !isBilibiliBangumiPage(url: currentURL)
                )

                Button {
                    if isBilibiliVideoPage(url: currentURL) {
                        triggerPlayPause()
                    }
                } label: {
                    Label("Play/Pause", systemImage: "playpause.fill")
                }
                .disabled(
                    !isBilibiliVideoPage(url: currentURL) && !isBilibiliBangumiPage(url: currentURL)
                )

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
        .clipShape(RoundedRectangle(cornerRadius: 10))  // Add this line to round the corners of the VStack
    }

    // Helper function to check if the current URL is a Bilibili video page
    private func isBilibiliVideoPage(url: URL) -> Bool {
        guard let host = url.host else { return false }
        if host.contains(appModel.bilibiliVideoHost) {
            if url.path.starts(with: appModel.bilibiliVideoPathPrefix) {
                return true
            }
        }
        return false
    }
    // Helper function to check if the current URL is a Bilibili Bangumi page
    private func isBilibiliBangumiPage(url: URL) -> Bool {
        guard let host = url.host else { return false }
        if host.contains(appModel.bilibiliVideoHost) {
            if url.path.starts(with: appModel.bilibiliBangumiPathPrefix) {
                return true
            }
        }
        return false
    }

    // Function to execute JavaScript for fullscreen
    private func triggerBilibiliFullscreen() -> Bool {

        print("Attempting to trigger fullscreen for video page.")
        // Create a completion group to wait for the JS evaluation
        var success = false
        let group = DispatchGroup()
        group.enter()

        let script = "el = document.querySelector('.bpx-player-ctrl-web'); el.click()"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution failed: \(error)")
                success = false
            } else {
                success = true
            }
            group.leave()
        }

        // Wait for JavaScript to complete with timeout
        let _ = group.wait(timeout: .now() + 0.2)
        return success
    }

    private func triggerPlayPause() {
        print("Attempting to trigger play/pause.")
        let script = "document.querySelector('.bpx-player-ctrl-play').click();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution for play/pause failed: \(error)")
            } else {
                print("JavaScript for play/pause executed. Result: \(String(describing: result))")
            }
        }
    }

    /// with class `bpx-player-ctrl-web-enter`
    private func triggerBilibiliBangumiFullscreen() -> Bool {
        print("Attempting to trigger fullscreen for Bangumi page.")
        // Create a completion group to wait for the JS evaluation
        var success = false
        let group = DispatchGroup()
        group.enter()

        // TODO for some reasons, the element is unreachable, although DOM exists
        let script = "el = document.querySelector('.bpx-player-ctrl-web-enter'); el.click()"
        // let script = "Array.from(document.getElementsByClassName('bpx-player-ctrl-btn')).map(function(el) { return el.className; }).join(',')"
        // let script = "document.getElementsByClassName('bpx-player-control-bottom-left').outterHTML"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution failed: \(error)")
                success = false
            } else {
                print("JavaScript execution result: \(String(describing: result))")
                success = true
            }
            group.leave()
        }

        // Wait for JavaScript to complete with timeout
        let _ = group.wait(timeout: .now() + 0.2)
        return success
    }

    /// with class
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
