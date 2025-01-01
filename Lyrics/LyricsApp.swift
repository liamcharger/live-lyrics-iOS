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
    
    @StateObject var viewModel = AuthViewModel.shared
    @StateObject var storeKitManager = StoreKitManager()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage(showNewSongKey) var showNewSong = false
    @AppStorage(showNewFolderKey) var showNewFolder = false
    
    init() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "df6aebfe758b46a1c5c8421e06e96fa4" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        FirebaseApp.configure()
        
        // NWPathMonitor has a bug that forces getNetworkState() to return false on first fetch, fetch once on launch to unlock correct results
        let _ = NetworkManager.shared.getNetworkState()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(storeKitManager)
                .onOpenURL { url in
                    if viewModel.currentUser != nil {
                        if url.absoluteString == "live-lyrics://profile" {
                            MainViewModel.shared.showProfileView = true
                        } else if url.absoluteString == "live-lyrics://share-invites" {
                            MainViewModel.shared.showShareInvites = true
                        }
                    }
                }
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
                            QuickAction.selectedAction = nil
                        case "new_folder":
                            showNewFolder = true
                            QuickAction.selectedAction = nil
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
    @Environment(\.scenePhase) var phase
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let remoteNotification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotification(userInfo: remoteNotification)
        }
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let deviceToken: [String: String] = ["token": fcmToken ?? ""]
        print("Device token:", deviceToken)
        if let currentUser = authViewModel.currentUser, let token = deviceToken.values.first, !deviceToken.isEmpty && token != currentUser.fcmId ?? "" { // Avoid unnecessary writes by checking if we really need to update the FCM id
            authViewModel.updateFCMId(currentUser, id: token)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received notification: handleNotification(userInfo: userInfo, openDeepLink: false)")
        handleNotification(userInfo: userInfo, openDeepLink: false)
        completionHandler([.badge, .banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Received user interaction: handleNotification(userInfo: userInfo, processNotification: false, openDeepLink: true)")
        handleNotification(userInfo: userInfo, processNotification: false, openDeepLink: true)
        completionHandler()
    }
    
    private func handleNotification(userInfo: [AnyHashable: Any], processNotification: Bool = true, openDeepLink: Bool = false) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID:", messageID)
        }
        
        if processNotification, let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let subtitle = alert["body"] as? String {
            mainViewModel.receivedNotificationFromFirebase(Notification(title: title, body: subtitle))
        }
        
        if openDeepLink, let deepLink = userInfo["deep_link"] as? String {
            print(deepLink)
            if let url = URL(string: deepLink) {
                UIApplication.shared.open(url)
            }
        }
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
    
    func registerForNotifications(completion: @escaping() -> Void) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        completion()
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
