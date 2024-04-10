//
//  Extensions.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import SwiftUI
import SwiftUIIntrospect

let showNotesDescKey = "showNotesDesc"
let showNewSongKey = "showNewSongKey"
let showNewFolderKey = "showNewFolderKey"

func hasHomeButton() -> Bool {
    if let keyWindow = UIApplication.shared.windows.first {
        let bottomInset = keyWindow.safeAreaInsets.bottom
        return bottomInset == 0
    }
    
    return true
}

extension View {
    @ViewBuilder
    func showPlayViewTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(PlayViewTip(), arrowEdge: .top)
        }
    }
    
    @ViewBuilder
    func showAutoScrollSpeedTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(AutoscrollSpeedTip(), arrowEdge: .top)
        }
    }
    
    @ViewBuilder public func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}

extension Song {
    static let song = Song(id: "noSongs", uid: "", timestamp: Date(), title: "noSongs", lyrics: "", order: 0, size: 0, key: "", notes: "", lineSpacing: 1.0)
}

extension Folder {
    static let folder = Folder(uid: "", timestamp: Date(), title: "noFolders", order: 0)
}

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

extension Color {
    static var materialRegularGray: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 34/255, green: 34/255, blue: 36/255, alpha: 1.0)
            } else {
                return UIColor(red: 240/255, green: 240/255, blue: 243/255, alpha: 1.0)
            }
        })
    }
}

final class ScrollDelegate: NSObject, UITableViewDelegate, UIScrollViewDelegate {
    var isScrolling: Binding<Bool>?
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let isScrolling = isScrolling?.wrappedValue,!isScrolling {
            self.isScrolling?.wrappedValue = true
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let isScrolling = isScrolling?.wrappedValue, isScrolling {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                self.isScrolling?.wrappedValue = false
            }
        }
    }
    // When the user slowly drags the scrollable control, decelerate is false after the user releases their finger, so the scrollViewDidEndDecelerating method is not called.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if let isScrolling = isScrolling?.wrappedValue, isScrolling {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    self.isScrolling?.wrappedValue = false
                }
            }
        }
    }
}
extension View {
    func scrollStatusByIntrospect(isScrolling: Binding<Bool>) -> some View {
        modifier(ScrollStatusByIntrospectModifier(isScrolling: isScrolling))
    }
}
struct ScrollStatusByIntrospectModifier: ViewModifier {
    @State var delegate = ScrollDelegate()
    @Binding var isScrolling: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                self.delegate.isScrolling = $isScrolling
            }
            .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                scrollView.delegate = delegate
            }
    }
}
