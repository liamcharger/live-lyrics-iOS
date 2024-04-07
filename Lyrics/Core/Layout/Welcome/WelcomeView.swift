//
//  WelcomeView.swift
//  Touchbase
//
//  Created by Liam Willey on 3/14/23.
//

import SwiftUI

enum GridItemType {
    case full
    case outline
}

struct WelcomeView: View {
    @Environment(\.presentationMode) var presMode
    @ObservedObject var notificationManager = NotificationManager()
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    func gridItem(title: String, subtitle: String, imageName: String, type: GridItemType) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Image(systemName: imageName)
                    .font(.title.weight(.regular))
                    .padding([.top, .leading, .trailing], 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                }
                .padding(12)
            }
            .frame(minHeight: 170)
            .padding(12)
            .background(type == .full ? .blue : .clear)
            .foregroundColor(type == .full ? .white : .blue)
            .cornerRadius(15)
            .background {
                if type == .outline {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.blue, lineWidth: 3.5)
                }
            }
            Spacer()
        }
    }
    
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
                    HStack(spacing: 10) {
                        gridItem(title: "Brand new UI!", subtitle: "Completely redesigned interface for ease of access.", imageName: "sparkles", type: .full)
                        gridItem(title: "Folders", subtitle: "Organize your songs with folders.", imageName: "folder", type: .outline)
                    }
                    ItemDetailView(title: .constant("Recently Deleted"), image: .constant("trash"), subtitle: .constant("Never accidentally delete a song."))
                    ItemDetailView(title: .constant("Notes"), image: .constant("doc.text"), subtitle: .constant("Add notes to your song to keep track of things you want to remember."))
                    ItemDetailView(title: .constant("Keys"), image: .constant("music.note"), subtitle: .constant("Add a key to your songs so you never forget them."))
                    ItemDetailView(title: .constant("And More"), image: .constant("ellipsis.circle"), subtitle: .constant("Play View, new customization options, and more."))
                }
                .padding(.top, 20)
                .padding(5)
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
