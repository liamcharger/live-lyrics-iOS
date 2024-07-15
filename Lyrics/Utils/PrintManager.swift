//
//  PrintManager.swift
//  Lyrics
//
//  Created by Liam Willey on 7/15/24.
//

import Foundation
import UIKit

class CustomTextPageRenderer: UIPrintPageRenderer {
    var text: String
    var font: UIFont
    var lineSpacing: CGFloat
    var columnCount: Int
    
    init(text: String, font: UIFont, lineSpacing: CGFloat, columnCount: Int) {
        self.text = text
        self.font = font
        self.lineSpacing = lineSpacing
        self.columnCount = columnCount
        super.init()
    }
    
    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        super.drawPage(at: pageIndex, in: printableRect)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle()
        ]
        
        let textStorage = NSTextStorage(string: text, attributes: textAttributes)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: printableRect.width / CGFloat(columnCount), height: printableRect.height))
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        let columnWidth = printableRect.width / CGFloat(columnCount)
        var currentColumn = 0
        var currentY: CGFloat = 0
        
        while currentColumn < columnCount {
            textContainer.size = CGSize(width: columnWidth, height: printableRect.height - currentY)
            let range = layoutManager.glyphRange(for: textContainer)
            
            layoutManager.drawBackground(forGlyphRange: range, at: CGPoint(x: printableRect.origin.x + columnWidth * CGFloat(currentColumn), y: printableRect.origin.y + currentY))
            layoutManager.drawGlyphs(forGlyphRange: range, at: CGPoint(x: printableRect.origin.x + columnWidth * CGFloat(currentColumn), y: printableRect.origin.y + currentY))
            
            if range.length == 0 { break }
            
            currentColumn += 1
            if currentColumn >= columnCount {
                currentColumn = 0
                currentY += textContainer.size.height
            }
        }
    }
    
    private func paragraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        return style
    }
}
