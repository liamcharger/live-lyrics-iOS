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

func greeting(withName: Bool? = nil) -> String {
    let date = Date()
    let calendar = Calendar.current
    let currentHour = calendar.component(.hour, from: date)
    
    let withName = withName ?? false
    let fullname: String? = AuthViewModel.shared.currentUser?.fullname
    
    var greetingText = "Hello."
    switch currentHour {
    case 0..<12:
        if withName {
            if let fullname = fullname {
                greetingText = NSLocalizedString("good_morning_greeting", comment: "") + ", \n" + fullname + "!"
            } else {
                greetingText = NSLocalizedString("good_morning_greeting", comment: "") + "!"
            }
        } else {
            greetingText = NSLocalizedString("good_morning", comment: "")
        }
    case 12..<18:
        if withName {
            if let fullname = fullname {
                greetingText = NSLocalizedString("good_afternoon_greeting", comment: "") + ", \n" + fullname + "!"
            } else {
                greetingText = NSLocalizedString("good_afternoon_greeting", comment: "") + "!"
            }
        } else {
            greetingText = NSLocalizedString("good_afternoon", comment: "")
        }
    default:
        if withName {
            if let fullname = fullname {
                greetingText = NSLocalizedString("good_evening_greeting", comment: "") + ", \n" + fullname + "!"
            } else {
                greetingText = NSLocalizedString("good_evening_greeting", comment: "") + "!"
            }
        } else {
            greetingText = NSLocalizedString("good_evening", comment: "")
        }
    }
    return greetingText
}

func completionOnConnectionState(noConnection: @escaping() -> Void, connection: @escaping() -> Void) {
    if NetworkManager.shared.getNetworkState() {
        // Add extra second because otherwise it seems unnaturally quick
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            connection()
        }
    } else {
        noConnection()
    }
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
    func showAutoscrollSpeedTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(AutoscrollSpeedTip(), arrowEdge: .bottom)
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

extension SongVariation {
    static let variation = SongVariation(title: "noVariations", lyrics: "", songUid: "", songId: "")
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
    var isScrollingProgrammatically: Binding<Bool>?
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Set isProgrammaticScrolling to false when the user begins dragging
        isScrollingProgrammatically?.wrappedValue = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only update isScrolling if the scroll is not programmatically triggered
        if let isScrolling = isScrolling?.wrappedValue, !isScrolling, !(isScrollingProgrammatically?.wrappedValue ?? false) {
            self.isScrolling?.wrappedValue = true
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // Only update isScrolling if the scroll is not decelerating
            if let isScrolling = isScrolling?.wrappedValue, isScrolling, !(isScrollingProgrammatically?.wrappedValue ?? false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    self.isScrolling?.wrappedValue = false
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Only update isScrolling if the scroll is not programmatically triggered
        if let isScrolling = isScrolling?.wrappedValue, isScrolling, !(isScrollingProgrammatically?.wrappedValue ?? false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                self.isScrolling?.wrappedValue = false
            }
        }
    }
}

extension View {
    func scrollStatusByIntrospect(isScrolling: Binding<Bool>, isScrollingProgrammatically: Binding<Bool>) -> some View {
        modifier(ScrollStatusByIntrospectModifier(isScrolling: isScrolling, isScrollingProgrammatically: isScrollingProgrammatically))
    }
}
struct ScrollStatusByIntrospectModifier: ViewModifier {
    @State var delegate = ScrollDelegate()
    @Binding var isScrolling: Bool
    @Binding var isScrollingProgrammatically: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                self.delegate.isScrolling = $isScrolling
                self.delegate.isScrollingProgrammatically = $isScrollingProgrammatically
            }
            .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                scrollView.delegate = delegate
            }
    }
}

struct Wave: Shape {
    var strength: Double
    var frequency: Double
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        
        let wavelength = width / frequency
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            
            let sin = sin(relativeX)
            
            let y = strength * sin + midHeight
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return Path(path.cgPath)
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

extension URL {
    var isDeeplink: Bool {
        return scheme == "live-lyrics"
    }
    
    var deepLinkView: DeepLinkView? {
        guard isDeeplink else { return nil }
        
        switch host {
        case "profile": return .profile
        default: return nil
        }
    }
}

extension UserDefaults {
    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            self.set(encoded, forKey: key)
        }
    }
    
    func codable<T: Codable>(forKey key: String) -> T? {
        if let data = self.data(forKey: key) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(T.self, from: data) {
                return decoded
            }
        }
        return nil
    }
}
