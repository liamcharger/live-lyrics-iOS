//
//  WebView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/9/23.
//

import SwiftUI
#if os(iOS)
import WebKit

struct Web: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
 
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
        
        while ((request.httpBody?.isEmpty) != nil) {
            isLoading = false
        }
    }
}

struct WebView: View {
    
    @Environment(\.presentationMode) var presMode
    
    @State var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                #if os(iOS)
                Web(url: URL(string: "https://charger-tech-lyrics.web.app/privacypolicy.html")!, isLoading: $isLoading)
                #endif
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {presMode.wrappedValue.dismiss()}, label: {
                            Text("Done")
                                .font(.body.weight(.semibold))
                        })
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            #else
                .toolbar {
                    ToolbarItem {
                        Button(action: {presMode.wrappedValue.dismiss()}, label: {
                            Text("Done")
                                .font(.body.weight(.semibold))
                        })
                    }
                }
            #endif
        }
    }
}
#endif
