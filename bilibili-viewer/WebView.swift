import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  @Binding var url: URL
  @Binding var currentWebViewInstance: WKWebView?
  var onPageFinishLoad: ((URL) -> Void)?  // Callback for when page finishes loading

  func makeUIView(context: Context) -> WKWebView {
    print("WebView: makeUIView called. Creating new WKWebView for URL: \(url.absoluteString)")  // DEBUG
    let config = WKWebViewConfiguration()

    // 基础媒体配置
    config.allowsInlineMediaPlayback = true
    config.allowsAirPlayForMediaPlayback = true
    config.allowsPictureInPictureMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []

    // 启用现代Web特性
    let preferences = WKWebpagePreferences()
    preferences.allowsContentJavaScript = true
    config.defaultWebpagePreferences = preferences
    config.preferences.javaScriptCanOpenWindowsAutomatically = true

    // 启用高性能和硬件加速配置
    config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    config.preferences.setValue(true, forKey: "developerExtrasEnabled")
    config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

    // 优化渲染性能
    config.suppressesIncrementalRendering = false

    let wkWebView = WKWebView(frame: .zero, configuration: config)

    // 设置高版本Safari UserAgent，避免版本过低提示和画质限制
    wkWebView.customUserAgent =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"

    // 设置页面缩放以适配VisionOS（降低默认缩放以避免画质限制）
    wkWebView.scrollView.minimumZoomScale = 0.5
    wkWebView.scrollView.maximumZoomScale = 3.0
    wkWebView.scrollView.zoomScale = 1.1  // 默认放大10%，减少对画质的影响
    wkWebView.scrollView.bouncesZoom = true

    wkWebView.navigationDelegate = context.coordinator
    wkWebView.uiDelegate = context.coordinator  // Set the UIDelegate
    context.coordinator.onPageFinishLoad = onPageFinishLoad  // Pass the callback to coordinator

    // Update the binding to provide the WKWebView instance to the parent view
    // Doing this asynchronously ensures the view is fully set up.
    DispatchQueue.main.async {
      context.coordinator.parent.currentWebViewInstance = wkWebView
    }
    return wkWebView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    print(
      "WebView: updateUIView called. Target URL: \(url.absoluteString). Current uiView.url: \(uiView.url?.absoluteString ?? "nil")"
    )  // DEBUG
    context.coordinator.onPageFinishLoad = onPageFinishLoad  // Ensure coordinator has the latest callback
    // Only load if the URL is different from the current one to avoid reload loops
    // and ensure that programmatic URL changes from ContentView are reflected.
    var currentURL = uiView.url?.absoluteString ?? ""
    currentURL = currentURL.replacingOccurrences(of: "%3A", with: ":")
    do {
      // dirty trick to avoid reload loop
      let regex = try NSRegularExpression(pattern: "&vd_source=[^&]*", options: [])
      currentURL = regex.stringByReplacingMatches(
        in: currentURL, options: [], range: NSRange(location: 0, length: currentURL.utf16.count),
        withTemplate: ""
      )
    } catch {
      print("Error creating regex: \(error)")
    }
    if currentURL != url.absoluteString {
      print(
        "WebView: Reloading - target URL (\(url.absoluteString)) is different from uiView.url (\(uiView.url?.absoluteString ?? "nil"))."
      )  // DEBUG
      let request = URLRequest(url: url)
      uiView.load(request)
    } else {
      print("WebView: Not reloading - URL strings match.")  // DEBUG
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self, onPageFinishLoad: onPageFinishLoad)
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {  // Add WKUIDelegate
    var parent: WebView
    var onPageFinishLoad: ((URL) -> Void)?

    init(_ parent: WebView, onPageFinishLoad: ((URL) -> Void)?) {
      self.parent = parent
      self.onPageFinishLoad = onPageFinishLoad
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      // If navigation finishes and the URL is different, update the binding.
      // This allows ContentView to know the current URL even if the user navigates within the WebView.
      if let newURL = webView.url {
        if newURL.absoluteString != parent.url.absoluteString {
          DispatchQueue.main.async {
            self.parent.url = newURL
          }
        }

        // 注入CSS样式来优化VisionOS显示效果
        injectVisionOSOptimizedCSS(webView: webView)

        // Call the onPageFinishLoad callback
        onPageFinishLoad?(newURL)
      }
    }

    private func injectVisionOSOptimizedCSS(webView: WKWebView) {
      let cssCode = """
          /* VisionOS触控优化 */
          button, a, input {
            min-height: 44px !important;
            min-width: 44px !important;
          }

          /* 优化滚动条 */
          ::-webkit-scrollbar {
            width: 16px !important;
          }

          ::-webkit-scrollbar-thumb {
            background-color: rgba(0,0,0,0.3) !important;
            border-radius: 8px !important;
          }

          /* B站视频播放器进度条优化 */
          .bpx-player-progress {
            height: 16px !important;
            min-height: 16px !important;
          }

          .bpx-player-progress-schedule {
            height: 16px !important;
          }

          .bpx-player-progress-schedule-wrap {
            height: 16px !important;
          }

          /* B站播放器控制按钮优化 */
          .bpx-player-ctrl-btn {
            min-height: 44px !important;
            min-width: 44px !important;
            padding: 8px 12px !important;
          }

          .bpx-player-ctrl-quality,
          .bpx-player-ctrl-playbackrate,
          .bpx-player-ctrl-subtitle {
            min-height: 44px !important;
            min-width: 44px !important;
          }

          /* 播放器菜单项优化 */
          .bpx-player-ctrl-quality-menu-item,
          .bpx-player-ctrl-playbackrate-menu-item {
            min-height: 44px !important;
            padding: 8px 16px !important;
            line-height: 28px !important;
          }

          /* nav buttons */
          .v-popover-wrap {
            min-width: 56px !important;
          }
          .download-client-trigger {
            display: none !important;
          }
        """

      let jsCode =
        "var style = document.createElement('style'); style.innerHTML = `\(cssCode)`; document.head.appendChild(style);"

      webView.evaluateJavaScript(jsCode) { result, error in
        if let error = error {
          print("CSS注入失败: \(error.localizedDescription)")
        } else {
          print("VisionOS触控优化CSS注入成功")
        }
      }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      print("WebView navigation failed: \(error.localizedDescription)")
    }

    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      print("WebView provisional navigation failed: \(error.localizedDescription)")
    }

    // Handle requests to open new windows
    func webView(
      _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
      for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
      if navigationAction.targetFrame == nil {
        webView.load(navigationAction.request)
      }
      return nil
    }
  }
}
