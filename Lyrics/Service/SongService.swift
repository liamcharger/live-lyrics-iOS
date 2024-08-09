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
	func fetchSongs(completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs")
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
	
	func fetchSharedSongs(completion: @escaping([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-songs")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching shared songs: \(error.localizedDescription)")
					completion([])
					return
				}
				
				guard let documents = snapshot?.documents else {
					print("No shared song documents found")
					completion([])
					return
				}
				
				var completedSongs = [Song]()
				let group = DispatchGroup()
				
				for document in documents {
					guard let sharedSong = try? document.data(as: SharedSong.self) else {
						continue
					}
					group.enter()
					self.fetchSong(listen: false, forUser: sharedSong.from, withId: sharedSong.songId, songCompletion: { song in
						if var song = song {
							song.variations = sharedSong.variations
							song.readOnly = sharedSong.readOnly
							song.pinned = sharedSong.pinned
							song.performanceMode = sharedSong.performanceMode
							completedSongs.append(song)
						}
						group.leave()
					}, registrationCompletion: { _ in })
				}
				
				group.notify(queue: .main) {
					completion(completedSongs)
				}
			}
	}

	
	func fetchSharedFolders(completion: @escaping([Folder]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-folders")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching shared folders: \(error.localizedDescription)")
					completion([])
				}
				
				guard let documents = snapshot?.documents else {
					print("No shared folder documents found")
					completion([])
					return
				}
				
				var completedFolders = [Folder]()
				let group = DispatchGroup()
				
				let sharedFolders = documents.compactMap({ try? $0.data(as: SharedFolder.self) })
				
				for sharedFolder in sharedFolders {
					group.enter()
					Firestore.firestore().collection("users").document(sharedFolder.from).collection("folders").document(sharedFolder.folderId).getDocument { snapshot, error in
						if let error = error {
							print(error.localizedDescription)
						}
						guard let snapshot = snapshot, snapshot.exists else {
							print("Folder does not exist")
							return
						}
						
						guard var folder = try? snapshot.data(as: Folder.self) else {
							print("Error parsing folder")
							return
						}
						
						folder.readOnly = sharedFolder.readOnly
						completedFolders.append(folder)
						group.leave()
					}
				}
				
				group.notify(queue: .main) {
					completion(completedFolders)
				}
			}
	}
	
	func fetchSharedSong(user: User, song: Song, completion: @escaping(SharedSong) -> Void) {
		guard let uid = user.id else { return }
		guard let songId = song.id else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(songId).getDocument { snapshot, error in
			if let error = error {
				print(error.localizedDescription)
			}
			
			guard let sharedSong = try? snapshot?.data(as: SharedSong.self) else {
				print("SharedSong object not found.")
				return
			}
			
			completion(sharedSong)
		}
	}
	
	func fetchSharedFolder(user: User, folder: Folder, completion: @escaping(SharedFolder) -> Void) {
		guard let uid = user.id else { return }
		guard let folderId = folder.id else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-folders").document(folderId).getDocument { snapshot, error in
			if let error = error {
				print(error.localizedDescription)
			}
			
			guard let sharedFolder = try? snapshot?.data(as: SharedFolder.self) else {
				print("SharedFolder object not found.")
				return
			}
			
			completion(sharedFolder)
		}
	}
	
	func fetchRecentlyDeletedSongs(completion: @escaping ([RecentlyDeletedSong]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
		
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching songs: \(error.localizedDescription)")
					completion([])
					return
				}
				
				guard let documents = snapshot?.documents else { return }
				
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
				
				if songs.isEmpty {
					completion([RecentlyDeletedSong(uid: "", timestamp: Date(), folderIds: [], deletedTimestamp: Date.now, title: "noSongs", lyrics: "", order: 0)])
				} else {
					completion(songs)
				}
			}
	}
	
	func fetchSongs(forUid: String? = nil, _ folder: Folder, completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let folderId = folder.id!
		let userId = folder.uid ?? uid
		
		guard !userId.isEmpty, !folderId.isEmpty else {
			print("Invalid userId or folderId")
			completion([])
			return
		}
		
		Firestore.firestore()
			.collection("users")
			.document(userId)
			.collection("folders")
			.document(folderId)
			.collection("songs")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching songs: \(error.localizedDescription)")
					completion([])
					return
				}
				
				guard let documents = snapshot?.documents else {
					print("No documents found")
					completion([])
					return
				}
				
				var completedSongs = [Song]()
				let group = DispatchGroup()
				let folderSongs = documents.compactMap { try? $0.data(as: FolderSong.self) }
				
				for folderSong in folderSongs {
					print(folderSong.id ?? "" + ", ", folderSong.order)
					group.enter()
					let songUid = folderSong.uid ?? userId
					self.fetchSong(listen: false, forUser: songUid, withId: folderSong.id!) { song in
						if let song = song {
							completedSongs.append(song)
						}
						group.leave()
					} registrationCompletion: { _ in }
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
	
	func fetchSong(listen: Bool? = nil, forUser: String? = nil, withId id: String, songCompletion: @escaping (Song?) -> Void, registrationCompletion: @escaping (ListenerRegistration?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			songCompletion(nil)
			registrationCompletion(nil)
			return
		}
		
		let userId = forUser ?? uid
		
		let documentReference = Firestore.firestore()
			.collection("users")
			.document(userId)
			.collection("songs")
			.document(id)
		
		if (listen ?? true) == true {
			let listenerReg = documentReference.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error listening to song \(id): \(error.localizedDescription)")
					songCompletion(nil)
					return
				}
				guard let snapshot = snapshot, let song = try? snapshot.data(as: Song.self) else {
					print("Error parsing song or song does not exist: \(id)")
					songCompletion(nil)
					return
				}
				songCompletion(song)
			}
			registrationCompletion(listenerReg)
		} else {
			documentReference.getDocument { snapshot, error in
				if let error = error {
					print("Error fetching song with ID \(id): \(error.localizedDescription)")
					songCompletion(nil)
					registrationCompletion(nil)
					return
				}
				guard let snapshot = snapshot, snapshot.exists, let song = try? snapshot.data(as: Song.self) else {
					print("Error parsing song or song does not exist: \(id)")
					songCompletion(nil)
					registrationCompletion(nil)
					return
				}
				songCompletion(song)
				registrationCompletion(nil)
			}
		}
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
		
		Firestore.firestore().collection("users").document(uid).collection("folders")
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
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations")
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					return
				}
				let variations = documents.compactMap({ try? $0.data(as: SongVariation.self) })
				
				completion(variations)
			}
	}
	
	func updateBpb(song: Song, bpb: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["bpb": bpb]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateBpm(song: Song, bpm: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["bpm": bpm]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updatePerformanceMode(song: Song, performanceMode: Bool) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		var ref: DocumentReference
		
		if uid != song.uid {
			ref = Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id!)
		} else {
			ref = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
		}
		
		ref.updateData(["performanceMode": performanceMode]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateTitle(folder: Folder, title: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!)
			.updateData(["title": title]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateSong(_ song: Song, title: String, key: String, artist: String, duration: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["title": title, "key": key, "artist": artist, "duration": duration]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateLyrics(forVariation: SongVariation? = nil, song: Song, lyrics: String) {
		if let variation = forVariation {
			print("Updating variation")
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!)
				.updateData(["lyrics": lyrics]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		} else {
			print("Updating default")
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
				.updateData(["lyrics": lyrics]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		}
	}
	
	func updateNotes(song: Song, notes: String) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["notes": notes]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateNotes(folder: Folder, notes: String) {
		Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!)
			.updateData(["notes": notes]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func fetchNotes(song: Song, completion: @escaping(String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).addSnapshotListener { snapshot, error in
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else { return }
			
			completion(song.notes ?? "")
		}
	}
	
	func fetchNotes(folder: Folder, completion: @escaping(String) -> Void) {
		Firestore.firestore().collection("users").document(folder.uid!).collection("songs").document(folder.id!).addSnapshotListener { snapshot, error in
			guard let snapshot = snapshot else { return }
			guard let folder = try? snapshot.data(as: Folder.self) else { return }
			
			completion(folder.notes ?? "")
		}
	}
	
	func updateTextProperties(song: Song, size: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["size": size]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, weight: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["weight": weight]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, lineSpacing: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["lineSpacing": lineSpacing]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, alignment: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["alignment": alignment]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	// UNUSED: will be implemented when folder detail views are created
	func createSong(folder: Folder, lyrics: String, artist: String, title: String, key: String, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let id = UUID().uuidString
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(id)
			.setData(["lyrics": lyrics, "timestamp": Date.now, "title": title, "artist": artist, "key": key, "order": 0, "size": 18, "uid": uid, "lineSpacing": 1]) { error in
				if let error = error {
					print("Error creating song: \(error.localizedDescription)")
					completion(false, error.localizedDescription)
				}
				Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id!).collection("songs").document(id)
					.setData(["order": 0]) { error in
						if let error = error {
							print("Error creating song: \(error.localizedDescription)")
							completion(false, error.localizedDescription)
						}
						completion(true, "Sucess!")
					}
			}
	}
	
	func createSong(lyrics: String, artist: String, key: String, title: String, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document()
		
		documentRef.setData(["lyrics": lyrics, "timestamp": Date.now, "title": title, "key": key, "artist": artist, "order": 0, "size": 18, "uid": uid, "lineSpacing": 1]) { error in
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
		
		let documentRef = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(id)
		
		documentRef.setData(["title": title, "lyrics": lyrics, "songUid": uid, "songId": song.id!]) { error in
			if let error = error {
				print("Error creating song variation: \(error.localizedDescription)")
				completion(error, "")
				return
			}
			
			completion(nil, id)
		}
	}
	
	func createSong(withUid: String? = nil, song: Song, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id!)
		let songData: [String: Any?] = [
			"uid": withUid ?? uid,
			"timestamp": Date(),
			"title": song.title,
			"lyrics": song.lyrics,
			"order": song.order,
			"size": song.size,
			"key": song.key,
			"notes": song.notes,
			"weight": song.weight,
			"alignment": song.alignment,
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
	
	func createFolder(withUid: String? = nil, folder: Folder, id: String? = nil, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let folderData = [
			"title": folder.title,
			"uid": withUid ?? uid,
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
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id!).collection("songs").document(song.id!).delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func deleteVariation(song: Song, variation: SongVariation) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!).delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateVariation(song: Song, variation: SongVariation, title: String) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!).updateData(["title": title]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func deleteSong(song: RecentlyDeletedSong) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id!).delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
			} else {
				print("Song deleted successfully")
			}
		}
	}
	
	// UNUSED: may be implemented to remove song refs from folders on delete
	func deleteSongRef(id: String, folder: Folder) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id!).collection("songs").document(id).delete { error in
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
			"lineSpacing": song.lineSpacing,
			"artist": song.artist,
			"bpm": song.bpm,
			"bpb": song.bpb,
			"pinned": song.pinned,
			"performanceMode": song.performanceMode,
			"duration": song.duration,
			"tags": song.tags
		]
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id!).setData(songData) { error in
			if let error = error {
				print(error.localizedDescription)
				return
			}
		}
		Firestore.firestore().collection("users").document(uid).collection("recentlydeleted").document(song.id!).delete { error in
			if let error = error {
				print("Error deleting song document: \(error.localizedDescription)")
				return
			}
		}
	}
	
	func deleteFolder(_ folder: Folder) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id!).delete { error in
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
		let recentlyDeletedRef = userRef.collection("recentlydeleted").document(song.id!)
		
		if let folder = folder {
			let folderRef = userRef.collection("folders").document(folder.id!)
			let folderSongsRef = folderRef.collection("songs")
			folderSongsRef.document(song.id!).delete { error in
				if let error = error {
					completion(false, error.localizedDescription)
					return
				}
			}
		}
		
		let userSongsRef = userRef.collection("songs")
		userSongsRef.document(song.id!).delete { error in
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
		guard let userId = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(userId).collection("folders").document(id).collection("songs")
		
		for song in songs {
			let songDocumentRef = songsCollectionRef.document(song.id!)
			
			songDocumentRef.setData(["order": 0, "uid": song.uid]) { error in
				if let error = error {
					completion(error)
				} else {
					completion(nil)
				}
			}
		}
	}
	
	func pinSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		if uid != song.uid {
			Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id!).updateData(["pinned": true])
		} else {
			Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id!).updateData(["pinned": true])
		}
	}
	
	func unpinSong(_ song: Song) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		if uid != song.uid {
			Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id!).updateData(["pinned": false])
		} else {
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).updateData(["pinned": false])
		}
	}
	
	func updateTagsForSong(_ song: Song, tags: [TagSelectionEnum], completion: @escaping((Error?) -> Void)) {
		guard let uid = Auth.auth().currentUser?.uid, let songId = song.id else { return }
		
		let filteredTags = tags.map { $0.rawValue }
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(songId).updateData(["tags": filteredTags.isEmpty ? FieldValue.delete() : filteredTags], completion: completion)
	}
	
	func sendInviteToUser(request: ShareRequest, includeDefault: Bool, completion: @escaping(Error?) -> Void) {
		let id = UUID().uuidString
		let dispatch = DispatchGroup()
		
		var songVariations = [String]()
		let variations = request.songVariations ?? []
		songVariations = variations + (includeDefault ? [SongVariation.defaultId] : [])

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
			"songVariations": songVariations,
			"readOnly": request.readOnly,
			"notificationTokens": request.notificationTokens,
			"fromNotificationToken": request.fromNotificationToken
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
				if let currentUser = AuthViewModel.shared.currentUser, let tokens = request.notificationTokens {
					UserService().sendNotificationToFCM(tokens: tokens, title: "Incoming Request", body: "\(currentUser.username) has sent a \(request.contentType == "folder" ? "folder" : "song").")
				}
				Firestore.firestore().collection("users").document(request.from).collection("songs").document(id).updateData(["joinedUsers":FieldValue.arrayUnion([request.from])])
				completion(nil)
			}
		}
	}
	
	func fetchIncomingInvites(completion: @escaping ([ShareRequest]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").addSnapshotListener { snapshot, error in
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
		
		Firestore.firestore().collection("users").document(uid).collection("outgoing-share-requests").addSnapshotListener { snapshot, error in
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
		deleteRequest(request, uid: incomingReqColUid ?? uid)
		group.leave()
		group.notify(queue: .main) {
			if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
				UserService().sendNotificationToFCM(tokens: [token], title: "Request Declined", body: "\(currentUser.username) has declined the \(request.contentType == "folder" ? "folder" : "song") \"\(request.contentName)\".")
			}
			completion()
		}
	}
	
	func acceptInvite(request: ShareRequest, completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let dispatch = DispatchGroup()
		var songs = [Song]()
		
		if request.contentType == "folder" {
			self.fetchFolder(forUser: request.from, withId: request.contentId) { folder in
				if let folder = folder {
					if request.type == "collaborate" {
						let sharedFolder: [String: Any] = [
							"from": request.from,
							"folderId": request.contentId,
							"order": 0,
							"readOnly": request.readOnly ?? false
						]
						
						dispatch.enter()
						Firestore.firestore().collection("users").document(uid).collection("shared-folders").document(folder.id!).setData(sharedFolder) { error in
							dispatch.leave()
							if let error = error {
								print("Error: \(error.localizedDescription)")
							}
						}
						
						dispatch.enter()
						Firestore.firestore().collection("users").document(request.from).collection("folders").document(folder.id!).updateData(["joinedUsers": FieldValue.arrayUnion([uid])]) { error in
							dispatch.leave()
							if let error = error {
								print("Error: \(error.localizedDescription)")
							}
						}
						
						dispatch.notify(queue: .main) {
							self.deleteRequest(request, uid: uid)
							completion()
						}
					} else {
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
						self.fetchSongs(forUid: request.from, folder) { folderSongs in
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
							self.moveSongsToFolder(id: folder.id!, songs: songs) { error in
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
							if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
								UserService().sendNotificationToFCM(tokens: [token], title: "Request Accepted", body: "\(currentUser.username) has accepted the folder \"\(request.contentName)\".")
							}
							completion()
						}
					}
				}
			}
		} else {
			dispatch.enter()
			self.fetchSong(listen: false, forUser: request.from, withId: request.contentId) { fetchedSong in
				dispatch.leave()
				let dispatch = DispatchGroup()
				
				guard let song = fetchedSong else {
					print("Error: Failed to fetch the song")
					return
				}
				
				if request.type == "collaborate" {
					let sharedSong: [String: Any?] = [
						"from": request.from,
						"songId": request.contentId,
						"order": 0,
						"variations": request.songVariations,
						"readOnly": request.readOnly
					]
					
					dispatch.enter()
					Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id!).setData(sharedSong) { error in
						dispatch.leave()
						if let error = error {
							print("Error: \(error.localizedDescription)")
						}
					}
					dispatch.enter()
					Firestore.firestore().collection("users").document(request.from).collection("songs").document(request.contentId).updateData(["joinedUsers": FieldValue.arrayUnion([uid])]) { error in
						dispatch.leave()
						if let error = error {
							print("Error: \(error.localizedDescription)")
						}
					}
					
					dispatch.notify(queue: .main) {
						self.deleteRequest(request, uid: uid)
						if let currentUser = AuthViewModel.shared.currentUser, let tokens = request.notificationTokens {
							UserService().sendNotificationToFCM(tokens: tokens, title: "Request Accepted", body: "\(currentUser.username) has accepted the song \"\(request.contentName)\". Tap to view.")
						}
						completion()
					}
				} else {
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
						"lineSpacing": song.lineSpacing,
						"artist": song.artist,
						"bpm": song.bpm,
						"bpb": song.bpb,
						"performanceMode": song.performanceMode,
						"duration": song.duration
					]
					
					let id = UUID().uuidString
					
					dispatch.enter()
					Firestore.firestore().collection("users").document(uid).collection("songs").document(id).setData(songData) { error in
						if let error = error {
							print(error.localizedDescription)
						}
						dispatch.leave()
					}
					dispatch.enter()
					Firestore.firestore().collection("users").document(request.from).collection("songs").document(id).collection("variations").getDocuments { snapshot, error in
						dispatch.leave()
						guard let documents = snapshot?.documents else { return }
						let variations = documents.compactMap({ try? $0.data(as: SongVariation.self )})
						
						for variation in variations {
							dispatch.enter()
							if let variations = request.songVariations, variations.contains(where: { $0 == variation.id ?? ""}) {
								Firestore.firestore().collection("users").document(uid).collection("songs").document(id).collection("variations").document(variation.id ?? "").setData(["lyrics": variation.lyrics, "songId": variation.songId, "songUid": variation.songUid, "title": variation.title]) { error in
									if let error = error {
										print(error.localizedDescription)
									}
									dispatch.leave()
								}
							}
						}
						
						dispatch.notify(queue: .main) {
							self.deleteRequest(request, uid: uid)
							if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
								UserService().sendNotificationToFCM(tokens: [token], title: "Request Accepted", body: "\(currentUser.username) has accepted the song \"\(request.contentName)\".")
							}
							completion()
						}
					}
				}
			} registrationCompletion: { _ in }
		}
	}
	
	func deleteRequest(_ request: ShareRequest, uid: String) {
		Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id!).delete { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}
		}
		Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id!).delete { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}
		}
	}
	
	func leaveCollabSong(forUid: String? = nil, song: Song, completion: @escaping() -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }

		Firestore.firestore().collection("users").document(forUid ?? uid).collection("shared-songs").document(song.id!).delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).updateData(["joinedUsers": FieldValue.arrayRemove([forUid ?? uid])]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
		completion()
	}
	
	func leaveCollabFolder(forUid: String? = nil, folder: Folder, completion: @escaping() -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let dispatch = DispatchGroup()
		
		dispatch.enter()
		Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!).updateData(["joinedUsers": FieldValue.arrayRemove([forUid ?? uid])]) { error in
			dispatch.leave()
			if let error = error {
				print(error.localizedDescription)
			}
		}
		
		dispatch.enter()
		Firestore.firestore().collection("users").document(forUid ?? uid).collection("shared-folders").document(folder.id!).delete { error in
			dispatch.leave()
			if let error = error {
				print(error.localizedDescription)
			}
		}
		
		dispatch.notify(queue: .main) {
			completion()
		}
	}
}
