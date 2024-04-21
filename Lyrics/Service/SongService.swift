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
	var variationListener: ListenerRegistration?
	var recentSongListener: ListenerRegistration?
	var incomingInvitesListener: ListenerRegistration?
	var outgoingInvitesListener: ListenerRegistration?
	
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
	
	func removeIncomingInviteEventListener() {
		incomingInvitesListener?.remove()
	}

	func removeOutgoingInviteEventListener() {
		outgoingInvitesListener?.remove()
	}

	func removeSongVariationListener() {
		variationListener?.remove()
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
					let noSongs = RecentlyDeletedSong(uid: "", timestamp: Date(), folderIds: [], deletedTimestamp: Date.now, title: "noSongs", lyrics: "", order: 0)
					completion([noSongs])
					return
				}
				
				let group = DispatchGroup()
				var songs: [RecentlyDeletedSong] = []
				
				for document in documents {
					group.enter()
					if let song = try? document.data(as: RecentlyDeletedSong.self) {
						if song.deletedTimestamp < thirtyDaysAgo {
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
	
	func fetchSongs(returnEmptySong: Bool? = nil, forUid: String? = nil, _ folder: Folder? = nil, folderId: String? = nil, completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let folderId = folder?.id ?? (folderId ?? "")
		
		self.folderSongListener = Firestore.firestore().collection("users").document(forUid ?? uid).collection("folders").document(folderId).collection("songs")
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
					self.fetchSong(forUser: forUid ?? uid, withId: songId) { song in
						if let song = song {
							completedSongs.append(song)
						}
						group.leave()
					} registrationCompletion: { _ in }
				}
				
				group.notify(queue: .main) {
					if completedSongs.isEmpty {
						completion(returnEmptySong ?? true ? [Song.song] : [])
					} else {
						completion(completedSongs)
					}
				}
			}
	}
	
	func fetchSong(forUser: String? = nil, withId id: String, folder: Folder? = nil, songCompletion: @escaping (Song?) -> Void, registrationCompletion: @escaping (ListenerRegistration?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let reg = Firestore.firestore().collection("users").document(forUser ?? uid).collection("songs").document(id).addSnapshotListener { snapshot, error in
			if let error = error {
				print("Error fetching song with ID \(id): \(error.localizedDescription)")
				songCompletion(nil)
				registrationCompletion(nil)
				return
			}
			
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else {
				print("Error parsing song: \(id)")
				songCompletion(nil)
				registrationCompletion(nil)
				return
			}
			
			songCompletion(song)
		}
		registrationCompletion(reg)
	}
	
	func fetchFolder(forUser: String? = nil, withId id: String, folder: Folder? = nil, completion: @escaping (Folder?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(forUser ?? uid).collection("folders").document(id).getDocument { snapshot, error in
			if let error = error {
				print("Error fetching folder with ID \(id): \(error.localizedDescription)")
				completion(nil)
				return
			}
			
			guard let snapshot = snapshot else { return }
			guard let folder = try? snapshot.data(as: Folder.self) else {
				print("Error parsing folder: \(id)")
				completion(nil)
				return
			}
			completion(folder)
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
	
	func fetchSongVariations(song: Song, completion: @escaping([SongVariation]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		self.variationListener = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").collection("variations")
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					return
				}
				let variations = documents.compactMap({ try? $0.data(as: SongVariation.self) })
				
				if variations.isEmpty {
					completion([SongVariation.variation])
				} else {
					completion(variations)
				}
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
	
	func updateBpb(song: Song, bpb: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["bpb": bpb]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateBpm(song: Song, bpm: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["bpm": bpm]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updatePerformanceMode(song: Song, performanceMode: Bool) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["performanceMode": performanceMode]) { error in
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
	
	func updateTitle(folder: Folder, title: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(folder.uid ?? "").collection("folders").document(folder.id ?? "")
			.updateData(["title": title]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateSong(_ song: Song, title: String, key: String, artist: String, duration: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["title": title, "key": key, "artist": artist, "duration": duration]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateTextProperties(folder: Folder, song: Song, size: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("folders").document(folder.id ?? "").collection("songs").document(song.id ?? "")
			.updateData(["size": size]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateLyrics(forVariation: SongVariation? = nil, song: Song, lyrics: String) {
		if let variation = forVariation {
			print("Updating variation")
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").collection("variations").document(variation.id ?? "")
				.updateData(["lyrics": lyrics]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		} else {
			print("Updating default")
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
				.updateData(["lyrics": lyrics]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		}
	}
	
	func updateNotes(song: Song, notes: String) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["notes": notes]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func fetchNotes(song: Song, completion: @escaping(String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").addSnapshotListener { snapshot, error in
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else { return }
			
			completion(song.notes ?? "")
		}
	}
	
	func fetchEditDetails(_ song: Song, completion: @escaping(String, String, String, String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.getDocument { snapshot, error in
				guard let snapshot = snapshot else { return }
				guard let selectedSong = try? snapshot.data(as: Song.self) else { return }
				
				completion(selectedSong.title, selectedSong.key ?? "Not Set", selectedSong.artist ?? "Not Set", selectedSong.duration ?? "Not Set")
			}
	}
	
	func updateTextProperties(song: Song, size: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["size": size]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, design: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["design": design]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, weight: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["weight": weight]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, lineSpacing: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
			.updateData(["lineSpacing": lineSpacing]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, alignment: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "")
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
	
	func createSongVariation(song: Song, lyrics: String, title: String, completion: @escaping(Error?, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let id = UUID().uuidString
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").collection("variations").document(id)
		
		documentRef.setData(["title": title, "lyrics": lyrics, "songUid": uid, "songId": song.id ?? "", ]) { error in
			if let error = error {
				print("Error creating song variation: \(error.localizedDescription)")
				completion(error, "")
				return
			}
			
			completion(nil, id)
		}
	}
	
	func createSong(song: Song, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
		var songData: [String: Any?] = [
			"uid": uid,
			"timestamp": Date(),
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
			"bpb": song.bpb,
			"pinned": song.pinned,
			"performanceMode": song.performanceMode,
			"duration": song.duration,
			"tags": song.tags
		]
		
		completion(nil)
		documentRef.setData(songData) { error in
			if error != nil {
				completion(error)
				return
			}
			
			completion(nil)
		}
	}
	
	func createFolder(folder: Folder, id: String? = nil, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let folderData = [
			"title": folder.title,
			"uid": uid,
			"timestamp": Date(),
			"order": 0
		] as [String : Any]
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(id ?? UUID().uuidString)
			.setData(folderData) { error in
				if error != nil {
					completion(error)
				}
				completion(nil)
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
	
	func deleteVariation(song: Song, variation: SongVariation) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").collection("variations").document(variation.id ?? "").delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateVariation(song: Song, variation: SongVariation, title: String) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").collection("variations").document(variation.id ?? "").updateData(["title": title]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func deleteSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let batch = Firestore.firestore().batch()
		let dispatch = DispatchGroup()
		
		let songRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
		batch.deleteDocument(songRef)
		
		dispatch.enter()
		for folder in MainViewModel.shared.folders {
			let folderRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(song.id ?? "")
			batch.deleteDocument(folderRef)
			dispatch.leave()
		}
		
		dispatch.notify(queue: .main) {
			batch.commit { error in
				if let error = error {
					print("Error deleting song documents: \(error.localizedDescription)")
				} else {
					print("Song deleted successfully")
				}
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
	
	func deleteSongRef(id: String, folder: Folder) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "").collection("songs").document(id).delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				print("Song ref deleted successfully")
			}
		}
	}
	
	func restoreSong(song: RecentlyDeletedSong) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songData: [String: Any?] = [
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
			"bpb": song.bpb,
			"pinned": song.pinned,
			"performanceMode": song.performanceMode,
			"duration": song.duration,
			"tags": song.tags
		]
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "").setData(songData) { error in
			if let error = error {
				print(error.localizedDescription)
				return
			}
		}
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id ?? "").delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
				return
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
	
	func moveSongToRecentlyDeleted(song: Song, from folder: Folder? = nil, completion: @escaping (Bool, String?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion(false, "User not authenticated.")
			return
		}
		
		var songData: [String: Any?] = [
			"uid": song.uid,
			"timestamp": song.timestamp,
			"deletedTimestamp": Date(),
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
			"bpb": song.bpb,
			"pinned": song.pinned,
			"performanceMode": song.performanceMode,
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
	
	func moveSongsToFolder(id: String, songs: [Song], completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(id).collection("songs")
		
		for song in songs {
			let songDocumentRef = songsCollectionRef.document(song.id ?? "")
			
			songDocumentRef.setData(["order": 0]) { error in
				if error != nil {
					completion(error)
					return
				}
				completion(nil)
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
		
		let songRef = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(songId)
		
		songRef.updateData(["tags": tags.map { $0.rawValue }], completion: completion)
	}
	
	func fetchPinStatus(song: Song, completion: @escaping(Bool) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id ?? "").addSnapshotListener { snapshot, error in
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
	
	func sendInviteToUser(request: ShareRequest, completion: @escaping(Error?) -> Void) {
		let id = UUID().uuidString
		let dispatch = DispatchGroup()
		
		let requestData: [String: Any?] = [
			"timestamp": request.timestamp,
			"from": request.from,
			"to": request.to,
			"contentId": request.contentId,
			"contentType": request.contentType,
			"contentName": request.contentName,
			"type": request.type,
			"toUsername": request.toUsername,
			"fromUsername": request.fromUsername,
			"songVariations": request.songVariations
		]
		
		Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(id).setData(requestData) { error in
			if let error = error {
				completion(error)
				print(error.localizedDescription)
				return
			}
			
			for toUser in request.to {
				dispatch.enter()
				Firestore.firestore().collection("users").document(toUser).collection("incoming-share-requests").document(id).setData(requestData) { error in
					if let error = error {
						completion(error)
						print(error.localizedDescription)
					}
					
					dispatch.leave()
				}
			}
			
			dispatch.notify(queue: .main) {
				// Send notification to user's device
				//		if let fcmId = toUser.fcmId {
				//			UserService().sendNotificationToFCM(deviceToken: fcmId, title: "Live Lyrics", body: "\(fromUser.username) has sent a song. Tap to view.")
				//		}
				
				completion(nil)
			}
		}
	}
	
	func fetchIncomingInvites(completion: @escaping ([ShareRequest]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		self.incomingInvitesListener =  Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").addSnapshotListener { snapshot, error in
			if let error = error {
				print(error.localizedDescription)
				return
			}
			
			guard let documents = snapshot?.documents else {
				print("No incoming invites")
				completion([])
				return
			}
			
			let incomingInvites = documents.compactMap { try? $0.data(as: ShareRequest.self) }
			completion(incomingInvites)
		}
	}
	
	func fetchOutgoingInvites(completion: @escaping ([ShareRequest]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		self.outgoingInvitesListener =  Firestore.firestore().collection("users").document(uid).collection("outgoing-share-requests").addSnapshotListener { snapshot, error in
			if let error = error {
				print(error.localizedDescription)
				return
			}
			
			guard let documents = snapshot?.documents else {
				print("No outgoing invites")
				completion([])
				return
			}
			
			let outgoingInvites = documents.compactMap { try? $0.data(as: ShareRequest.self) }
			completion(outgoingInvites)
		}
	}
	
	func declineInvite(incomingReqColUid: String? = nil, request: ShareRequest, completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let group = DispatchGroup()
		
		group.enter()
		Firestore.firestore().collection("users").document(incomingReqColUid ?? uid).collection("incoming-share-requests").document(request.id ?? "").delete { error in
			defer { group.leave() }
			if let error = error {
				print("Error deleting incoming share request: \(error.localizedDescription)")
			}
		}
		
		group.enter()
		Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id ?? "").delete { error in
			defer { group.leave() }
			if let error = error {
				print("Error deleting outgoing share request: \(error.localizedDescription)")
			}
		}
		
		group.notify(queue: .main) {
			completion()
		}
	}
	
	func acceptInvite(request: ShareRequest, completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let dispatch = DispatchGroup()
		var song: Song?
		var songs = [Song]()
		
		if request.contentType == "folder" {
			self.fetchFolder(forUser: request.from, withId: request.contentId) { folder in
				if let folder = folder {
					dispatch.enter()
					self.createFolder(folder: folder, id: request.contentId) { error in
						dispatch.leave()
						if let error = error {
							print("Error: \(error.localizedDescription)")
							completion()
							return
						}
					}
					dispatch.enter()
					self.fetchSongs(returnEmptySong: false, forUid: request.from, folder) { folderSongs in
						for song in folderSongs {
							self.createSong(song: song) { error in
								if let error = error {
									print(error.localizedDescription)
									completion()
									return
								}
								songs.append(song)
							}
						}
						self.moveSongsToFolder(id: folder.id ?? "", songs: songs) { error in
							if let error = error {
								print(error.localizedDescription)
								completion()
								return
							}
						}
						dispatch.leave()
					}
					
					dispatch.notify(queue: .main) {
						self.deleteRequest(request, uid: uid)
						completion()
					}
				}
			}
		} else {
			dispatch.enter()
			self.fetchSong(forUser: request.from, withId: request.contentId) { fetchedSong in
				song = fetchedSong
				dispatch.leave()
				
				if let song = song {
					let songData: [String: Any?] = [
						"uid": uid,
						"timestamp": Date(),
						"deletedTimestamp": Date(),
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
						"bpb": song.bpb,
						"pinned": song.pinned,
						"performanceMode": song.performanceMode,
						"duration": song.duration,
						"tags": song.tags
					]
					
					Firestore.firestore().collection("users").document(uid).collection("songs").document(request.contentId).setData(songData)
					Firestore.firestore().collection("users").document(request.from).collection("songs").document(request.contentId).collection("variations").getDocuments { snapshot, error in
						guard let documents = snapshot?.documents else { return }
						let variations = documents.compactMap({ try? $0.data(as: SongVariation.self )})
						
						for variation in variations {
							if let variations = request.songVariations, variations.contains(where: { $0 == variation.id ?? ""}) {
								Firestore.firestore().collection("users").document(uid).collection("songs").document(request.contentId).collection("variations").document(variation.id ?? "").setData(["lyrics": variation.lyrics, "songId": variation.songId, "songUid": variation.songUid, "title": variation.title])
							}
						}
					}
					self.deleteRequest(request, uid: uid)
				}
			} registrationCompletion: { _ in }
		}
	}
	
	func deleteRequest(_ request: ShareRequest, uid: String) {
		Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id ?? "").delete { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}
		}
		Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id ?? "").delete { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}
		}
	}
}
