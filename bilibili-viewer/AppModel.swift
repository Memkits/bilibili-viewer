//
//  AppModel.swift
//  bilibili-viewer
//
//  Created by chen on 2025/5/11.
//

import Combine  // Ensure Combine is imported for ObservableObject
import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable  // This macro should provide ObservableObject conformance automatically
class AppModel: ObservableObject {  // Explicitly conform to ObservableObject
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    var videoPlayerURL: URL? = nil
    var showVideoPlayerWindow: Bool = false

    // Constants for Bilibili URLs
    let bilibiliHomeURL = URL(string: "https://www.bilibili.com")!
    let bilibiliSearchURLBase = "https://search.bilibili.com/all?keyword="
    let bilibiliVideoHost = "www.bilibili.com"
    let bilibiliVideoPathPrefix = "/video/BV"
    let bilibiliPlayerURLBase = "https://player.bilibili.com/player.html?isOutside=true&autoplay=1"  // Added autoplay=1

    func getVideoPlayerURL(from bilibiliVideoURL: URL) -> URL? {
        guard bilibiliVideoURL.host == bilibiliVideoHost,
            bilibiliVideoURL.path.starts(with: bilibiliVideoPathPrefix)
        else {
            return nil
        }
        // Extract bvid, assuming format /video/BVID/...
        let pathComponents = bilibiliVideoURL.pathComponents
        if pathComponents.count > 2 {
            let bvid = pathComponents[2]
            return URL(string: "\(bilibiliPlayerURLBase)&bvid=\(bvid)&page=1&high_quality=1")
        }
        return nil
    }
}
