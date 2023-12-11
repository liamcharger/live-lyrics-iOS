//
//  RichTextEditorViewController.swift
//  Lyrics
//
//  Created by Liam Willey on 7/3/23.
//

#if os(iOS)
import UIKit

class RichTextEditorViewController: UIViewController {
    let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextView()
    }
    
    private func setupTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Example function to apply formatting to selected text
    private func applyFormatting() {
        let selectedRange = textView.selectedRange
        
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: selectedRange)
        
        textView.attributedText = attributedString
    }
}
#endif
