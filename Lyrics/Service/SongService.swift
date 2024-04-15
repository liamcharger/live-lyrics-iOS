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
		
		let group = DispatchGroup()
		
		var songs = [Song]()
		
		group.enter()
		
		self.songListener = Firestore.firestore().collection("users").document(uid).collection("songs")
			.order(by: "order")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching songs: \(error.localizedDescription)")
					group.leave()
					return
				}
				guard let documents = snapshot?.documents else {
					print("No documents found")
					group.leave()
					return
				}
				
				songs = documents.compactMap({ try? $0.data(as: Song.self) })
				
				group.leave()
			}
		
		group.enter()
		
		self.fetchSharedSongs { fetchedSongs in
			songs.append(contentsOf: fetchedSongs)
			print(fetchedSongs)
			group.leave()
		}
		
		group.notify(queue: .main) {
			completion(songs)
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
	
	func fetchSongs(id: String? = nil, _ folder: Folder, completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		guard let folderId = folder.id else { return }
		
		self.folderSongListener = Firestore.firestore().collection("users").document(id ?? uid).collection("folders").document(folderId).collection("songs")
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
					self.fetchSong(userColId: id, withId: songId) { song in
						if let song = song {
							completedSongs.append(song)
						} else {
							Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(songId).getDocument { snapshot, error in
								if let error = error {
									print("Error fetching shared song with ID \(songId): \(error.localizedDescription)")
									group.leave()
									return
								}
								
								guard let snapshot = snapshot else {
									group.leave()
									return
								}
								
								guard let sharedSong = try? snapshot.data(as: SharedSong.self) else {
									group.leave()
									return
								}
								
								group.enter()
								self.fetchSong(withId: sharedSong.songId) { song in
									if let song = song {
										completedSongs.append(song)
									}
									group.leave()
								}
							}
						}
						group.leave()
					}
				}
				
				group.notify(queue: .main) {
					self.fetchSharedSongs(folder) { fetchedSongs in
						completedSongs.append(contentsOf: fetchedSongs)
						if completedSongs.isEmpty {
							completion([Song.song])
						} else {
							completion(completedSongs)
						}
					}
				}
			}
	}
	
	func fetchSharedSongs(_ folder: Folder? = nil, completion: @escaping([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-songs")
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					print("No documents found")
					completion([])
					return
				}
				
				var completedSongs = [Song]()
				let group = DispatchGroup()
				
				let sharedSongs = documents.compactMap({ try? $0.data(as: SharedSong.self) })
				
				for sharedSong in sharedSongs {
					group.enter()
					self.fetchSong(forUser: sharedSong.from, withId: sharedSong.songId) { song in
						if let song = song {
							completedSongs.append(song)
						}
						group.leave()
					}
				}
				
				group.notify(queue: .main) {
					completion(completedSongs)
				}
			}
	}
	
	func fetchSong(userColId: String? = nil, withId id: String, folder: Folder? = nil, completion: @escaping (Song?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(userColId ?? uid).collection("songs").document(id).getDocument { snapshot, error in
			if let error = error {
				print("Error fetching song with ID \(id): \(error.localizedDescription)")
				completion(nil)
				return
			}
			
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else {
				print("Error parsing song: \(id)")
				if let folder = folder {
					self.fetchRecentlyDeletedSongs { songs in
						print(songs)
						if !songs.contains(where: { $0.id == id }) {
							self.deleteSongRef(id: id, folder: folder)
						}
					}
				}
				completion(nil)
				return
			}
			completion(song)
		}
	}
	
	func fetchSong(forUser: String, withId id: String, folder: Folder? = nil, completion: @escaping (Song?) -> Void) {
		Firestore.firestore().collection("users").document(forUser).collection("songs").document(id).getDocument { snapshot, error in
			if let error = error {
				print("Error fetching song with ID \(id): \(error.localizedDescription)")
				completion(nil)
				return
			}
			
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else {
				print("Error parsing song: \(id)")
				completion(nil)
				return
			}
			completion(song)
		}
	}
	
	func fetchFolder(forUser: String, withId id: String, folder: Folder? = nil, completion: @escaping (Folder?) -> Void) {
		Firestore.firestore().collection("users").document(forUser).collection("folders").document(id).getDocument { snapshot, error in
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
	
	func updateBpb(song: Song, bpb: Int) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["bpb": bpb]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateBpm(song: Song, bpm: Int) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
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
		guard let uid = Auth.auth().currentUser?.uid else { return }
		Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "")
			.updateData(["title": title]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateSong(_ song: Song, title: String, key: String, artist: String, duration: String, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["title": title, "key": key, "artist": artist, "duration": duration]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
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
	
	func createSong(song: Song, completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let documentRef = Firestore.firestore().collection("users").document(uid).collection("songs").document()
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
		
		completion(true, "")
		documentRef.setData(songData) { error in
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
	
	func createFolder(folder: Folder, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let folderData = [
			"title": folder.title,
			"uid": uid,
			"timestamp": Date(),
			"order": 0
		] as [String : Any]
		
		Firestore.firestore().collection("users").document(uid).collection("folders").document()
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
	
	func moveSongsToFolder(toFolder: Folder, songs: [Song], completion: @escaping(Bool, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(toFolder.id ?? "").collection("songs")
		
		for song in songs {
			let songDocumentRef = songsCollectionRef.document(song.id ?? "")
			
			songDocumentRef.setData(["order": 0]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
					return
				}
				completion(true, "")
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
	
	func sendInviteToUser(request: ShareRequest, completion: @escaping(Error?) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
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
			"fromUsername": request.fromUsername
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
	
	func declineInvite(request: ShareRequest, completion: @escaping() -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let batch = Firestore.firestore().batch()
		
		// TODO: Implement logic to check if it's the last user to join, and if so, delete the outgoing request from the sender's collection
		
		let incomingRequestRef = Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id ?? "")
		let outgoingRequestRef = Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id ?? "")
		batch.deleteDocument(incomingRequestRef)
		batch.deleteDocument(outgoingRequestRef)
		
		batch.commit { error in
			if let error = error {
				print("Error committing batch operation: \(error.localizedDescription)")
				return
			}
			// Send notification to user's device
			//		if let fcmId = toUser.fcmId {
			//			UserService().sendNotificationToFCM(deviceToken: fcmId, title: "Live Lyrics", body: "\(fromUser.username) has declined a shared \(request.contentType.lowercased()).")
			//		}
		}
	}
	
	func acceptInvite(request: ShareRequest, completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let batch = Firestore.firestore().batch()
		let dispatch = DispatchGroup()
		var song: Song?
		
		if request.contentType == "folder" {
			if request.type == "collaborate" {
				// TODO: Implement collaboration logic
			} else if request.type == "copy" {
				
			}
		} else {
			dispatch.enter()
			self.fetchSong(forUser: request.from, withId: request.contentId) { fetchedSong in
				song = fetchedSong
				dispatch.leave()
				
				if let song = song {
					if request.type == "collaborate" {
						dispatch.enter()
						let data: [String: Any] = [
							"songId": song.id ?? "",
							"order": 0,
							"from": request.from
						]
						batch.setData(data, forDocument: Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(request.contentId))
						dispatch.leave()
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
						
						let songRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(request.contentId)
						batch.setData(songData, forDocument: songRef)
						
						let requestRef1 = Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id ?? "")
						batch.deleteDocument(requestRef1)
						
						let requestRef2 = Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id ?? "")
						batch.deleteDocument(requestRef2)
					}
				}
				
				dispatch.notify(queue: .main) {
					batch.commit { error in
						if let error = error {
							print("Error committing batch: \(error.localizedDescription)")
							return
						}
						completion()
						// Send notification to user's device
						//		if let fcmId = toUser.fcmId {
						//			UserService().sendNotificationToFCM(deviceToken: fcmId, title: "Live Lyrics", body: "\(fromUser.username) has accepted a shared \(request.contentType.lowercased()).")
						//		}
					}
				}
			}
		}
	}
}
