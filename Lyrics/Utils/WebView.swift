//
//  WebView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/9/23.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var urlToDisplay: URL?
    
    @Binding var isLoading: Bool
    @Binding var progress: Double
    
    init(urlToDisplay: String, isLoading: Binding<Bool>, progress: Binding<Double>) {
        self.urlToDisplay = URL(string: urlToDisplay)
        self._isLoading = isLoading
        self._progress = progress
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        if let urlWeb = urlToDisplay {
            let request = URLRequest(url:urlWeb)
            webView.load(request)
        }
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, isLoading: $isLoading)
    }
    
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        @Binding var isLoading: Bool
        
        init(_ parent: WebView, isLoading: Binding<Bool>) {
            self._isLoading = isLoading
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
            }
            parent.progress = 1.0
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.progress = Double(webView.estimatedProgress)
        }
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presMode
    
    @State private var isLoading: Bool = false
    @State private var progress: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    WebView(urlToDisplay: "https://live-lyrics.web.app/privacypolicy", isLoading: $isLoading, progress: $progress)
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {presMode.wrappedValue.dismiss()}, label: {
                        Text("Done")
                            .font(.body.weight(.semibold))
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
