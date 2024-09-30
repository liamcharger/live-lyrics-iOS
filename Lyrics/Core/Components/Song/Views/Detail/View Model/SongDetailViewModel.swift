//
//  SongDetailViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 8/2/24.
//

import Foundation
import UIKit
import SwiftUI

class SongDetailViewModel: ObservableObject {
    @Published var showShareSheet = false
    @Published var showNotesView = false
    @Published var showEditView = false
    @Published var showDeleteSheet = false
    @Published var showLeaveSheet = false
    @Published var showMoveView = false
    @Published var showTagSheet = false
    
    @Published var demoToEdit: DemoAttachment?
    
    @Published var selectedText = ""
    
    @ObservedObject var songViewModel = SongViewModel.shared
    
    let pasteboard = UIPasteboard.general
    
    static let shared = SongDetailViewModel()
    
    func readOnly(_ song: Song) -> Bool {
        return song.readOnly ?? false
    }
    
    func optionsButton(_ song: Song, lyrics: String, isSongFromFolder: Bool) -> some View {
        Menu {
            if !readOnly(song) {
                Button {
                    self.showEditView = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if !songViewModel.isShared(song: song) {
                Button {
                    self.showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                self.printSong(song, lyrics)
            } label: {
                Label("Print", systemImage: "printer")
            }
            let move = Button {
                self.showMoveView = true
            } label: {
                Label("Move", systemImage: "folder")
            }
            if let selectedFolder = MainViewModel.shared.selectedFolder, isSongFromFolder {
                if selectedFolder.uid ?? "" == uid() {
                    move
                }
            } else {
                move
            }
            Menu {
                Button {
                    self.pasteboard.string = song.title
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    self.pasteboard.string = song.lyrics
                } label: {
                    Label("Copy Lyrics", systemImage: "doc.plaintext")
                }
#if DEBUG
                Button {
                    self.pasteboard.string = song.id ?? ""
                } label: {
                    Label("Copy Song ID", systemImage: "doc.on.doc")
                }
#endif
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            if !(song.readOnly ?? false) {
                Button {
                    self.showTagSheet = true
                } label: {
                    Label("Tags", systemImage: "tag")
                }
            }
            Button(role: .destructive, action: {
                if !self.songViewModel.isShared(song: song) {
                    self.showDeleteSheet = true
                } else {
                    self.showLeaveSheet = true
                }
            }, label: {
                if songViewModel.isShared(song: song) {
                    Label("Leave", systemImage: "arrow.backward.square")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            })
        } label: {
            FAText(iconName: "ellipsis", size: 18)
                .modifier(NavBarButtonViewModifier())
        }
    }
    
    func printSong(_ song: Song, _ lyrics: String) {
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = UIPrintInfo.OutputType.general
        printInfo.jobName = song.title
        printController.printInfo = printInfo
        
        let artistString = song.artist?.isEmpty == false ? "<div style='color: gray;'>\(song.artist!)</div>" : ""
        
        let htmlString = """
<html>
<head>
<style>
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        margin: 0;
        padding: 34px;
        box-sizing: border-box;
    }
    .content {
        column-count: 2;
        column-gap: 20px;
        column-fill: auto;
    }
    h2 {
        margin-bottom: 5px;
    }
    .gray-text {
        color: gray;
    }
</style>
</head>
<body>
<div>
    <h2>\(song.title)</h2>
    \(artistString)
</div>
<br/>
<div class="content">
    \(lyrics.replacingOccurrences(of: "\n", with: "<br/>"))
</div>
</body>
</html>
"""
        
        let formatter = UIMarkupTextPrintFormatter(markupText: htmlString)
        formatter.perPageContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        printController.printFormatter = formatter
        
        printController.present(animated: true, completionHandler: nil)
    }
    
    func getWeight(weight: Int) -> Font.Weight {
        switch weight {
        case 0:
            return .regular
        case 1:
            return .black
        case 2:
            return .bold
        case 3:
            return .heavy
        case 4:
            return .light
        case 5:
            return .medium
        case 6:
            return .regular
        case 7:
            return .semibold
        case 8:
            return .thin
        default:
            return .ultraLight
        }
    }
    
    func getAlignment(alignment: Int) -> TextAlignment {
        switch alignment {
        case 0:
            return .leading
        case 1:
            return .center
        case 2:
            return .trailing
        default:
            return .leading
        }
    }
    
    func removeFeatAndAfter(from input: String) -> String {
        let keyword = "feat"
        
        if let range = input.range(of: keyword, options: .caseInsensitive) {
            let substring = input[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            return String(substring)
        }
        
        return input
    }
  
    struct DatamuseRowViewModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(8)
                .padding(.horizontal, 4)
                .background(Material.thin)
                .foregroundColor(.primary)
                .clipShape(Capsule())
                .lineLimit(1)
        }
    }
}
