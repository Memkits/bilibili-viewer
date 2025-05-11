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

    var body: some View {
        VStack(spacing: 0) {
            WebView(url: $currentURL, currentWebViewInstance: $webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Button {
                    currentURL = appModel.bilibiliHomeURL
                } label: {
                    Label("Home", systemImage: "house.fill")
                }

                Button {
                    if let videoURL = appModel.getVideoPlayerURL(from: currentURL) {
                        appModel.videoPlayerURL = videoURL
                        appModel.showVideoPlayerWindow = true
                    } else {
                        // Optionally, provide feedback to the user that the current URL is not a valid video URL
                        print("Not a Bilibili video page or unable to parse URL.")
                    }
                } label: {
                    Label("Open Video Fullscreen", systemImage: "arrow.up.right.video.fill")
                }
                .disabled(appModel.getVideoPlayerURL(from: currentURL) == nil)  // Disable if not a video page

                Spacer()

                TextField("Search on Bilibili", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Button {
                    if let encodedSearchText = searchText.addingPercentEncoding(
                        withAllowedCharacters: .urlQueryAllowed),
                        let searchURL = URL(
                            string:
                                "\(appModel.bilibiliSearchURLBase)\(encodedSearchText)&from_source=webtop_search&spm_id_from=333.788&search_source=3"
                        )
                    {
                        currentURL = searchURL
                    }
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(searchText.isEmpty)

            }
            .padding()
            .background(.thinMaterial)
        }
        .onChange(of: currentURL) { _, newURL in
            // This ensures that if the user navigates within the WebView,
            // the 'Open Video Fullscreen' button's state is updated.
            print("Current URL changed to: \(newURL)")
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
