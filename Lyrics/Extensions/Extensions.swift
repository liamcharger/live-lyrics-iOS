//
//  Extensions.swift
//  Lyrics
//
//  Created by Liam Willey on 5/3/23.
//

import Foundation
import SwiftUI
import SwiftUIIntrospect

let showNewSongKey = "showNewSongKey"
let showNewFolderKey = "showNewFolderKey"

func hasHomeButton() -> Bool {
    if let keyWindow = UIApplication.shared.windows.first {
        let bottomInset = keyWindow.safeAreaInsets.bottom
        return bottomInset == 0
    }
    
    return true
}

func uid() -> String {
    return AuthViewModel.shared.currentUser?.id ?? ""
}

func greeting(withName: Bool? = nil) -> String {
    @AppStorage("fullname") var fullname: String?
    
    let date = Date()
    let calendar = Calendar.current
    let currentHour = calendar.component(.hour, from: date)
    
    let withName = withName ?? false
    
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

extension View {
    // Create a modifier for each tip because we can't pass a param ("Tip requires iOS 17.0 or newer")
    @ViewBuilder
    func showDatamuseCopyTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(DatamuseRowViewTip(), arrowEdge: .trailing)
                .tipViewStyle(LiveLyricsTipStyle())
        }
    }
    
    @ViewBuilder
    func showExploreDetailTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(ExploreDetailViewTip(), arrowEdge: .top)
                .tipViewStyle(LiveLyricsTipStyle())
        }
    }
    
    @ViewBuilder
    func showByRoleTip() -> some View {
        if #available(iOS 17, *) {
            self
                .popoverTip(ShareByRoleTip(), arrowEdge: .top)
                .tipViewStyle(LiveLyricsTipStyle())
        }
    }
    
    func rowCapsule() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Material.regular)
            .foregroundColor(.primary)
            .clipShape(Capsule())
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
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
                return UIColor(red: 42/255, green: 42/255, blue: 43/255, alpha: 1.0)
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
            .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)) { scrollView in
                scrollView.delegate = delegate
            }
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
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
