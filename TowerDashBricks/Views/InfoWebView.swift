import SwiftUI
import WebKit

/// Lightweight in-app browser for the Privacy Policy and Support pages.
/// Ported from `InfoWebScreen`.
struct InfoWebView: View {
    let title: String
    let url: String
    @Environment(\.dismiss) private var dismiss
    @State private var loading = true

    var body: some View {
        ZStack {
            AppColors.panelSolid.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        AudioService.shared.playSfx(.buttonClick); dismiss()
                    } label: {
                        Image(systemName: "arrow.left").font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                    }
                    Text(title).font(AppFont.button(20)).foregroundStyle(AppColors.text)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                ZStack {
                    WebView(url: url, loading: $loading)
                    if loading {
                        ProgressView().tint(AppColors.accent)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct WebView: UIViewRepresentable {
    let url: String
    @Binding var loading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor(AppColors.panelSolid)
        webView.isOpaque = false
        if let u = URL(string: url) {
            webView.load(URLRequest(url: u))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        init(_ parent: WebView) { self.parent = parent }
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.loading = true
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.loading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loading = false
        }
    }
}
