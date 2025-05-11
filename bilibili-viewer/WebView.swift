import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  @Binding var url: URL
  @Binding var currentWebViewInstance: WKWebView?

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    // Attempt to allow autoplay, though browser policies might still intervene
    config.mediaTypesRequiringUserActionForPlayback = []

    let wkWebView = WKWebView(frame: .zero, configuration: config)
    wkWebView.navigationDelegate = context.coordinator

    // Update the binding to provide the WKWebView instance to the parent view
    // Doing this asynchronously ensures the view is fully set up.
    DispatchQueue.main.async {
      context.coordinator.parent.currentWebViewInstance = wkWebView
    }
    return wkWebView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    // Only load if the URL is different from the current one to avoid reload loops
    // and ensure that programmatic URL changes from ContentView are reflected.
    if uiView.url?.absoluteString != url.absoluteString {
      let request = URLRequest(url: url)
      uiView.load(request)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, WKNavigationDelegate {
    var parent: WebView

    init(_ parent: WebView) {
      self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      // If navigation finishes and the URL is different, update the binding.
      // This allows ContentView to know the current URL even if the user navigates within the WebView.
      if let newURL = webView.url, newURL.absoluteString != parent.url.absoluteString {
        DispatchQueue.main.async {
          self.parent.url = newURL
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
  }
}
