import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  @Binding var url: URL
  @Binding var currentWebViewInstance: WKWebView?
  var onPageFinishLoad: ((URL) -> Void)?  // Callback for when page finishes loading

  func makeUIView(context: Context) -> WKWebView {
    print("WebView: makeUIView called. Creating new WKWebView for URL: \(url.absoluteString)")  // DEBUG
    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    // Attempt to allow autoplay, though browser policies might still intervene
    config.mediaTypesRequiringUserActionForPlayback = []

    let wkWebView = WKWebView(frame: .zero, configuration: config)
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
    if uiView.url?.absoluteString != url.absoluteString {
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
        // Call the onPageFinishLoad callback
        onPageFinishLoad?(newURL)
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
