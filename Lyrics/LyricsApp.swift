import SwiftUI
import Firebase
import UIKit
import FirebaseMessaging
import GoogleMobileAds
import FirebaseAnalytics
import TipKit

@main
struct LyricsApp: App {
    @Environment(\.scenePhase) var phase
    
    @StateObject var viewModel = AuthViewModel()
    @StateObject var storeKitManager = StoreKitManager()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    init() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "df6aebfe758b46a1c5c8421e06e96fa4" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(storeKitManager)
                .onChange(of: phase) { phase in
                    switch phase {
                    case .background:
                        QuickAction.addQuickItems()
                    case .inactive:
                        break
                    case .active:
                        switch QuickAction.selectedAction?.type {
                        case "new_song":
                            showNewSong = true
                        case "new_folder":
                            showNewSong = true
                        case .none:
                            break
                        case .some(_):
                            break
                        }
                    default:
                        break
                    }
                }
                .task {
                    if #available(iOS 17, *) {
                        do {
                            try Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
                        } catch {
                            print(error)
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    @ObservedObject var mainViewModel = MainViewModel()
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let deviceToken: [String: String] = ["token": fcmToken ?? ""]
        print("Device token:", deviceToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID:", messageID)
        }
        
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let subtitle = alert["body"] as? String {
            mainViewModel.receivedNotificationFromFirebase(Notification(title: title, subtitle: subtitle, imageName: "envelope"))
            print("Received notification: \(Notification(title: title, subtitle: subtitle, imageName: "enevelope"))")
        }

        completionHandler([.badge, .banner])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications:", error.localizedDescription)
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let selectedAction = options.shortcutItem {
            QuickAction.selectedAction = selectedAction
        }
        let sceneConfiguration = UISceneConfiguration (name: "Quick Action Scene", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = QuickActionSceneDelegate.self
        return sceneConfiguration
    }
}

class QuickActionSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        QuickAction.selectedAction = shortcutItem
    }
}

enum QuickAction {
    static var selectedAction: UIApplicationShortcutItem?
    
    static var shortcutItems = [
        UIApplicationShortcutItem(type: "new_folder", localizedTitle: "New Folder", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "folder.badge.plus")),
        UIApplicationShortcutItem(type: "new_song", localizedTitle: "New Song", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "square.and.pencil"))
    ]
    
    static func addQuickItems() {
        UIApplication.shared.shortcutItems = QuickAction.shortcutItems
    }
}
