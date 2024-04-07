//
//  SongService.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import FirebaseAuth
import Firebase
import CoreData

class SongService {
	var songListener: ListenerRegistration?
	var folderSongListener: ListenerRegistration?
	var folderListener: ListenerRegistration?
	var recentSongListener: ListenerRegistration?
	//	let context = PersistenceController.shared.container.viewContext
	
	//	func fetchLocalUser() -> LocalUser? {
	//		let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
	//
	//		do {
	//			let users = try context.fetch(request)
	//			return users.first
	//		} catch {
	//			print("Error fetching local user: \(error.localizedDescription)")
	//			return nil
	//		}
	//	}
	
	// Save local user data to Core Data
	//	func saveLocalUser(_ localUser: LocalUser) {
	//		do {
	//			try context.save()
	//		} catch {
	//			print("Error saving local user: \(error.localizedDescription)")
	//		}
	//	}
	
	func removeSongEventListener() {
		songListener?.remove()
	}
	
	func removeFolderSongEventListener() {
		folderSongListener?.remove()
	}
	
	func removeFolderEventListener() {
		folderListener?.remove()
	}
	
	func removeRecentSongEventListener() {
		recentSongListener?.remove()
	}
	
	func fetchSongs(completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		self.songListener = Firestore.firestore().collection("users").document(uid).collection("songs")
			.order(by: "order")
			.addSnapshotListener { snapshot, error in
				if error != nil {
					print("Error fetching songs...")
					return
				}
				guard let documents = snapshot?.documents else {
					print("No documents found")
					return
				}
				
				let songs = documents.compactMap({ try? $0.data(as: Song.self) })
				
				if documents.isEmpty {
					completion([Song.song])
				} else {
					completion(songs)
				}
			}
	}
	
	
	func fetchRecentlyDeletedSongs(completion: @escaping ([RecentlyDeletedSong]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
		
		self.recentSongListener = Firestore.firestore().collection("users").document(uid).collection("recentlydeleted")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching songs: \(error.localizedDescription)")
					completion([])
					return
				}
				
				guard let documents = snapshot?.documents else {
					print("No documents found")
					let noSongs = RecentlyDeletedSong(uid: "", timestamp: Date(), folderId: "", deletedTimestamp: Date.now, title: "noSongs", lyrics: "", order: 0)
					completion([noSongs])
					return
				}
				
				let group = DispatchGroup()
				var songs: [RecentlyDeletedSong] = []
				
				for document in documents {
					group.enter()
					if let song = try? document.data(as: RecentlyDeletedSong.self) {
						if song.timestamp < thirtyDaysAgo {
							document.reference.delete()
							group.leave()
						} else {
							songs.append(song)
							group.leave()
						}
					} else {
						group.leave()
					}
				}
				
				group.notify(queue: .main) {
					completion(songs)
				}
			}
	}
	
	func fetchSongs(_ folder: Folder, completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		guard let folderId = folder.id else { return }
		
		self.folderSongListener = Firestore.firestore().collection("users").document(uid).collection("folders").document(folderId).collection("songs")
			.order(by: "order")
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					print("No documents found")
					completion([])
					return
				}
				
				var completedSongs = [Song]()
				let group = DispatchGroup()
				
				for document in documents {
					group.enter()
					let songId = document.documentID
					self.fetchSong(withId: songId) { song in
						completedSongs.append(song)
						group.leave()
					}
				}
				
				group.notify(queue: .main) {
					if completedSongs.isEmpty {
						completion([Song.song])
					} else {
						completion(completedSongs)
					}
				}
			}
	}
	
	func fetchSong(withId id: String, completion: @escaping (Song) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(id).getDocument { snapshot, error in
			if let error = error {
				print("Error fetching song with ID \(id): \(error.localizedDescription)")
				return
			}
			
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else {
				print("There was an error parsing the song.")
				return
			}
			completion(song)
		}
	}
	
	func fetchFolders(completion: @escaping ([Folder]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		self.folderListener = Firestore.firestore().collection("users").document(uid).collection("folders")
			.order(by: "order")
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					return
				}
				let folders = documents.compactMap({ try? $0.data(as: Folder.self) })
				
				if folders.isEmpty {
					completion([Folder.folder])
				} else {
					completion(folders)
				}
			}
	}
	
	func fetchSongSettings(withId id: String, completion: @escaping (String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(id).getDocument { snapshot, error in
			if let error = error {
				print("Error fetching song with ID \(id): \(error.localizedDescription)")
				return
			}
			
			guard let snapshot = snapshot, let song = try? snapshot.data(as: Song.self) else {
				print("Could not parse song with ID \(id)")
				return
			}
			completion(song.duration ?? "")
		}
	}
	
	func updateSongSettings(songId: String, duration: String, completion: @escaping(Bool) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(songId)
			.updateData(["duration": duration]) { error in
				if let error = error {
					print(error.localizedDescription)
					completion(false)
					return
				}
				completion(true)
			}
	}
	
	func updateAutoscrollBool(songId: String, autoscrollEnabled: Bool, completion: @escaping(Bool) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(songId)
			.updateData(["enableAutoscroll": autoscrollEnabled]) { error in
				if let error = error {
					print(error.localizedDescription)
					completion(false)
					return
				}
				completion(true)
			}
	}
	
	func updateLyrics(folder: Folder, song: Song, lyrics: String) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(song.id ?? "")
			.updateData(["lyrics": lyrics]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateWordCountPreferences(preference: String, completion: @escaping(String, Bool) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid)
			.updateData(["wordCountStyle": preference]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completion(error.localizedDescription, false)
					} else {
						completion("", true)
					}
				}
			}
	}
	
	func updateTitle(folder: Folder, title: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "")
			.updateData(["title": title]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completionBool(false)
						completionString(error.localizedDescription)
					} else {
						completionBool(true)
					}
				}
			}
	}
	
	func updateTextProperties(folder: Folder, song: Song, size: Int) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(song.id ?? "")
			.updateData(["size": size]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateLyrics(song: Song, lyrics: String) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["lyrics": lyrics]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateNotes(song: Song, notes: String) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["notes": notes]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func fetchNotes(song: Song, completion: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").addSnapshotListener { snapshot, error in
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else { return }
			
			completion(song.notes ?? "")
		}
	}
	
	func fetchEditDetails(_ song: Song, completion: @escaping(String, String, String, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.getDocument { snapshot, error in
				guard let snapshot = snapshot else { return }
				guard let selectedSong = try? snapshot.data(as: Song.self) else { return }
				
				completion(selectedSong.title, selectedSong.key ?? "Not Set", selectedSong.artist ?? "Not Set", selectedSong.duration ?? "Not Set")
			}
	}
	
	func updateTitle(song: Song, title: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["title": title]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completionBool(false)
						completionString(error.localizedDescription)
					} else {
						completionBool(true)
					}
				}
			}
	}
	
	func updateDuration(song: Song, duration: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["duration": duration]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completionBool(false)
						completionString(error.localizedDescription)
					} else {
						completionBool(true)
					}
				}
			}
	}
	
	func updateArtist(song: Song, artist: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["artist": artist]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completionBool(false)
						completionString(error.localizedDescription)
					} else {
						completionBool(true)
					}
				}
			}
	}
	
	func updateKey(song: Song, key: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["key": key]) { error in
				DispatchQueue.main.async {
					if let error = error {
						completionBool(false)
						completionString(error.localizedDescription)
					} else {
						completionBool(true)
					}
				}
			}
	}
	
	func updateTextProperties(song: Song, size: Int) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["size": size]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, design: Double) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["design": design]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, weight: Double) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["weight": weight]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, lineSpacing: Double) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["lineSpacing": lineSpacing]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, alignment: Double) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["alignment": alignment]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func createSong(folder: Folder, lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let id = UUID().uuidString
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(id)
			.setData(["lyrics": lyrics, "timestamp": Date.now, "title": title, "order": 0, "size": 18, "uid": uid, "lineSpacing": 1]) { error in
				if let error = error {
					print("Error creating song: \(error.localizedDescription)")
					completion(false, error.localizedDescription)
				}
				Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(id)
					.setData(["order": 0]) { error in
						if let error = error {
							print("Error creating song: \(error.localizedDescription)")
							completion(false, error.localizedDescription)
						}
						completion(true, "Sucess!")
					}
			}
	}
	
	func createSong(lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document()
		
		documentRef.setData(["lyrics": lyrics, "timestamp": Date.now, "title": title, "order": 0, "size": 18, "uid": uid, "lineSpacing": 1]) { error in
			if let error = error {
				print("Error creating song: \(error.localizedDescription)")
				completion(false, error.localizedDescription)
				return
			}
			
			completion(true, "Success!")
		}
	}
	
	func addSongToMySongs(id: String, lyrics: String, title: String, artist: String?, timestamp: Date, key: String?, bpm: String?, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(id)
		
		documentRef.setData(["lyrics": lyrics, "timestamp": timestamp, "title": title, "uid": uid, "order": 0, "artist": artist]) { error in
			if let error = error {
				print("Error creating song: \(error.localizedDescription)")
				completion(false, error.localizedDescription)
				return
			}
			
			completion(true, "Success!")
		}
	}
	
	func createFolder(title: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document()
			.setData(["title": title, "timestamp": Date.now, "order": 0, "uid": uid]) { error in
				if let error = error {
					completionString(error.localizedDescription)
					completionBool(false)
				}
				completionBool(true)
			}
	}
	
	func deleteSong(_ folder: Folder, _ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(song.id ?? "").delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func deleteSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").getDocuments { snapshot, error in
			if let error = error {
				print("Error retrieving folder documents: \(error.localizedDescription)")
				return
			}
			
			guard let documents = snapshot?.documents else {
				print("No folder documents found")
				return
			}
			
			for document in documents {
				document.reference.collection("songs")
					.document(song.id ?? "").getDocument { snapshot, error in
						if let error = error {
							print("Error retrieving song document within folder: \(error.localizedDescription)")
							return
						}
						
						if let songDocument = snapshot, songDocument.exists {
							songDocument.reference.delete { error in
								if let error = error {
									print("Error deleting song document within folder: \(error.localizedDescription)")
								}
							}
						}
					}
			}
		}
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				print("Song deleted successfully")
			}
		}
	}
	
	func deleteSong(song: RecentlyDeletedSong) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id ?? "").delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				print("Song deleted successfully")
			}
		}
	}
	
	func restoreSong(song: RecentlyDeletedSong) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songData = [
			"uid": song.uid,
			"timestamp": song.timestamp,
			"title": song.title,
			"lyrics": song.lyrics,
			"order": song.order,
			"size": song.size,
			"key": song.key,
			"notes": song.notes,
			"weight": song.weight,
			"alignment": song.alignment,
			"design": song.design,
			"lineSpacing": song.lineSpacing,
			"artist": song.artist,
			"bpm": song.bpm,
			"pinned": song.pinned,
			"performanceView": song.performanceView,
			"autoscrollDuration": song.autoscrollDuration,
			"duration": song.duration
		] as [String: Any?]
		
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id ?? "").delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").setData(songData) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
			}
		}
	}
	
	func restoreSongtoFolder(song: RecentlyDeletedSong) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songData = [
			"uid": song.uid,
			"timestamp": song.timestamp,
			"title": song.title,
			"lyrics": song.lyrics,
			"order": song.order,
			"size": song.size,
			"key": song.key,
			"notes": song.notes,
			"weight": song.weight,
			"alignment": song.alignment,
			"design": song.design,
			"lineSpacing": song.lineSpacing,
			"artist": song.artist,
			"bpm": song.bpm,
			"pinned": song.pinned,
			"performanceView": song.performanceView,
			"autoscrollDuration": song.autoscrollDuration,
			"duration": song.duration,
			"tags": song.tags
		] as [String: Any?]
		
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id ?? "").delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").setData(songData) { error in
					if let error = error {
						print(error.localizedDescription)
					}
					Firestore.firestore().collection("users").document(uid).collection("folders").document(song.folderId ?? "").collection("songs").document(song.id ?? "").setData(["order": 0]) { error in
						if let error = error {
							print(error.localizedDescription)
						}
					}
				}
			}
		}
	}
	
	func deleteFolder(_ folder: Folder) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func moveSongToFolder(currentFolder: Folder, toFolder: Folder, song: Song, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(currentFolder.id ?? "").collection("songs").document(song.id ?? "")
			.delete { error in
				if let error = error {
					completionBool(false)
					completionString(error.localizedDescription)
					return
				}
				Firestore.firestore().collection("users").document(uid).collection("folders").document(toFolder.id ?? "").collection("songs").document(song.id ?? "")
					.setData(["order": 0]) { error in
						if let error = error {
							completionBool(false)
							completionString(error.localizedDescription)
							return
						}
						completionBool(true)
					}
			}
	}
	
	func moveSongToRecentlyDeleted(song: Song, from folder: Folder? = nil, completion: @escaping (Bool, String?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion(false, "User not authenticated.")
			return
		}
		
		var songData: [String: Any?] = [
			"uid": song.uid,
			"timestamp": song.timestamp,
			"deletedTimestamp": Date().timeIntervalSince1970,
			"title": song.title,
			"lyrics": song.lyrics,
			"order": song.order,
			"size": song.size,
			"key": song.key,
			"notes": song.notes,
			"weight": song.weight,
			"alignment": song.alignment,
			"design": song.design,
			"lineSpacing": song.lineSpacing,
			"artist": song.artist,
			"bpm": song.bpm,
			"pinned": song.pinned,
			"performanceView": song.performanceView,
			"autoscrollDuration": song.autoscrollDuration,
			"duration": song.duration,
			"tags": song.tags
		]
		
		let firestore = Firestore.firestore()
		let userRef = firestore.collection("users").document(uid)
		let recentlyDeletedRef = userRef.collection("recentlydeleted").document(song.id ?? "")
		
		if let folder = folder {
			let folderRef = userRef.collection("folders").document(folder.id ?? "")
			let folderSongsRef = folderRef.collection("songs")
			folderSongsRef.document(song.id ?? "").delete { error in
				if let error = error {
					completion(false, error.localizedDescription)
					return
				}
			}
		}
		
		let userSongsRef = userRef.collection("songs")
		userSongsRef.document(song.id ?? "").delete { error in
			if let error = error {
				completion(false, error.localizedDescription)
				return
			}
		}
		
		recentlyDeletedRef.setData(songData) { error in
			if let error = error {
				completion(false, error.localizedDescription)
			} else {
				completion(true, nil)
			}
		}
	}
	
	
	func moveSongToFolder(toFolder: Folder, song: Song, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(toFolder.id ?? "").collection("songs")
		
		let songDocumentRef = songsCollectionRef.document(song.id ?? "")
		
		songDocumentRef.getDocument { document, error in
			if let error = error {
				completionBool(false)
				completionString(error.localizedDescription)
				return
			}
			
			guard !(document?.exists ?? false) else {
				// Document exists, handle accordingly
				completionBool(false)
				completionString("\"\(song.title)\" is already in the specified folder.")
				return
			}
			
			// Document doesn't exist, proceed with creating it
			songDocumentRef.setData(["order": 0]) { error in
				if let error = error {
					completionBool(false)
					completionString(error.localizedDescription)
					return
				}
				completionBool(true)
			}
		}
	}
	
	func moveSongsToFolder(toFolder: Folder, songs: [Song], completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(toFolder.id ?? "").collection("songs")
		
		for song in songs {
			let songDocumentRef = songsCollectionRef.document(song.id ?? "")
			
			songDocumentRef.getDocument { document, error in
				if let error = error {
					completion(false, error.localizedDescription)
					return
				}
				
				guard !(document?.exists ?? false) else {
					// Document exists, handle accordingly
					completion(false, "\"\(song.title)\" is already in the specified folder.")
					return
				}
				
				// Document doesn't exist, proceed with creating it
				songDocumentRef.setData(["order": 0]) { error in
					if let error = error {
						completion(false, error.localizedDescription)
						return
					}
					completion(true, "")
				}
			}
		}
	}
	
	func pinSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").updateData(["pinned": true])
	}
	
	func unpinSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").updateData(["pinned": false])
	}
	
	func updateTagsForSong(_ song: Song, tags: [TagSelectionEnum], completion: @escaping((Error?) -> Void)) {
		guard let uid = Auth.auth().currentUser?.uid, let songId = song.id else { return }
		
		let songRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(songId)
		
		songRef.updateData(["tags": tags.map { $0.rawValue }], completion: completion)
	}
	
	func fetchPinStatus(song: Song, completion: @escaping(Bool) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").addSnapshotListener { snapshot, error in
			if let error = error {
				print(error.localizedDescription)
				return
			}
			
			guard let snapshot = snapshot, let song = try? snapshot.data(as: Song.self) else {
				return
			}
			
			if song.pinned ?? false {
				completion(true)
			} else {
				completion(false)
			}
		}
	}
}
