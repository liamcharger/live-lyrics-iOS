//
//  WelcomeView.swift
//  Touchbase
//
//  Created by Liam Willey on 3/14/23.
//

import SwiftUI

struct WelcomeView: View {
    // Enivronment & Object vars
    @Environment(\.presentationMode) var presMode
    @ObservedObject var notificationManager = NotificationManager()
    @ObservedObject var mainViewModel = MainViewModel()
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let persistenceController = PersistenceController()
    
    var body: some View {
        VStack(spacing: 0) {
            Text("What's New in Live Lyrics")
                .padding(.top)
                .padding()
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
            Divider()
                .padding(.horizontal, -16)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Image(systemName: "sparkles")
                                .font(.title.weight(.regular))
                                .padding([.top, .leading, .trailing], 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Brand new UI!")
                                    .font(.body.weight(.bold))
                                Text("Completely redesigned interface for ease of access.")
                                    .font(.footnote)
                                    .foregroundColor(Color(.white))
                            }
                            .padding(12)
                        }
                        .frame(minHeight: 155)
                        .padding(12)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        VStack(alignment: .leading) {
                            Image(systemName: "folder")
                                .font(.title.weight(.regular))
                                .padding([.top, .leading, .trailing], 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Folders")
                                    .font(.body.weight(.bold))
                                Text("Organize your songs with folders.")
                                    .font(.footnote)
                            }
                            .padding(12)
                        }
                        .frame(minHeight: 160)
                        .padding(12)
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.blue, lineWidth: 3.5)
                        }
                    }
                    .padding(.trailing, 2)
                    ItemDetailView(title: .constant("Recently Deleted"), image: .constant("trash"), subtitle: .constant("Never accidentally delete a song."))
                    ItemDetailView(title: .constant("Notes"), image: .constant("doc.text"), subtitle: .constant("Add notes to your song to keep track of things you want to remember."))
                    ItemDetailView(title: .constant("Keys"), image: .constant("music.note"), subtitle: .constant("Add a key to your songs so you never forget them."))
                    ItemDetailView(title: .constant("And More"), image: .constant("ellipsis.circle"), subtitle: .constant("Play View, new customization options, and more."))
                }
                .padding(.top, 20)
            }
            Divider().padding(.horizontal, -16)
            Button(action: {
                let version = notificationManager.getCurrentAppVersion()
                UserDefaults.standard.set(version, forKey: "savedVersion")
                
                presMode.wrappedValue.dismiss()
            }, label: {
                Text(NSLocalizedString("continue", comment: "Continue"))
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            })
            .background(Material.bar)
            .padding(.vertical)
        }
        .padding(.horizontal)
    }
}

struct ItemDetailView: View {
    @Binding var title: String
    @Binding var image: String
    @Binding var subtitle: String
    var body: some View {
        HStack {
            Image(systemName: image)
                .foregroundColor(.blue)
                .font(.title.weight(.regular))
                .frame(width: 60, height: 50)
                .clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background(Material.regular)
        .cornerRadius(15)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
