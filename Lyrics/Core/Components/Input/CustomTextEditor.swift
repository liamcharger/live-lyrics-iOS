//
//  CustomTextEditor.swift
//  Lyrics
//
//  Created by Liam Willey on 7/29/24.
//

import SwiftUI

struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var multilineTextAlignment: TextAlignment
    var font: UIFont
    var lineSpacing: Double
    var padding: UIEdgeInsets
    var isInputActive: FocusState<Bool>.Binding
    @Binding var showBlur: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.textAlignment = multilineTextAlignment.uiTextAlignment
        textView.font = font
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = padding
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.text = text
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.backgroundColor = .clear
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.textAlignment = multilineTextAlignment.uiTextAlignment
        uiView.font = font
        uiView.textContainerInset = padding
        uiView.textContainer.lineFragmentPadding = 0
        
        if isInputActive.wrappedValue {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else {
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIScrollViewDelegate {
        var parent: CustomTextEditor
        var offset: CGPoint = CGPoint(x: 0, y: 0)
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isInputActive.wrappedValue = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isInputActive.wrappedValue = false
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                let offsetY = scrollView.contentOffset.y
                let shouldShowBlur = offsetY >= 24
                
                if shouldShowBlur != self.parent.showBlur {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        self.parent.showBlur = shouldShowBlur
                    }
                }
            }
        }
    }
}

extension TextAlignment {
    var uiTextAlignment: NSTextAlignment {
        switch self {
        case .leading: return .left
        case .trailing: return .right
        case .center: return .center
        @unknown default: return .left
        }
    }
}
