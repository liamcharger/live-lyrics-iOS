//
//  SongService.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import FirebaseAuth
import Firebase
import FirebaseFirestore

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
				
				completion(songs)
			}
	}
	
	func fetchSharedSongs(completion: @escaping ([Song]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("shared-songs")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("Error fetching shared songs: \(error.localizedDescription)")
					completion([]) // Returning an empty list in case of an error
					return
				}
				
				guard let documents = snapshot?.documents else {
					print("No shared song documents found")
					completion([]) // Returning an empty list if no documents found
					return
				}
				
				var completedSongs = [Song]()
				let group = DispatchGroup()
				
				for document in documents {
					guard let sharedSong = try? document.data(as: SharedSong.self) else {
						continue // Skip if sharedSong can't be parsed
					}
					group.enter() // Enter the group before starting the async task
					
					self.fetchSong(listen: false, forUser: sharedSong.from, withId: sharedSong.songId, songCompletion: { song in
						if var song = song {
							// Add the additional properties from sharedSong
							song.variations = sharedSong.variations
							song.readOnly = sharedSong.readOnly
							song.pinned = sharedSong.pinned
							song.performanceMode = sharedSong.performanceMode
							song.bandId = sharedSong.bandId
							completedSongs.append(song)
						}
						group.leave() // Leave the group after the async task completes
					}, registrationCompletion: { _ in })
				}
				
				// Notify the completion after all async tasks are done
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
							group.leave()
							return
						}
						
						guard var folder = try? snapshot.data(as: Folder.self) else {
							print("Error parsing folder")
							group.leave()
							return
						}
						
						folder.readOnly = sharedFolder.readOnly
						folder.songVariations = sharedFolder.songVariations
						folder.bandId = sharedFolder.bandId
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
				
				completion(songs)
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
			.document(forUid ?? userId)
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
					group.enter()
					self.fetchSong(listen: false, forUser: folderSong.uid, withId: folderSong.id!) { song in
						if var song = song {
							// If the folder is from a band, pass it onto the song
							song.bandId = folder.bandId
							if let variations = folder.songVariations {
								if let bandId = folder.bandId, variations.contains(where: { $0 == "byRole" }) {
									// Fetch variations based on band roles
									self.handleVariations(song, bandId: bandId) { songVariations in
										song.variations = songVariations.compactMap({ $0.id })
										completedSongs.append(song) // Ensure song is appended after variations are set
										group.leave()
									}
								} else if variations.contains(where: { $0 == SongVariation.defaultId }) {
									var song = song
									song.variations = [SongVariation.defaultId]
									completedSongs.append(song)
									group.leave()
								} else if variations.isEmpty {
									song.variations = []
									completedSongs.append(song)
									group.leave()
								}
							} else {
								completedSongs.append(song)
								group.leave()
							}
						} else {
							group.leave()
						}
					} registrationCompletion: { _ in }
				}
				
				group.notify(queue: .main) {
					completion(completedSongs)
				}
			}
	}
	
	func handleVariations(_ song: Song, bandId: String, completion: @escaping ([SongVariation]) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion([])
			return
		}
		
		let group = DispatchGroup()
		var filteredVariations = [SongVariation]()
		
		group.enter()
		BandsViewModel.shared.fetchUserBands(withListener: false) {
			guard let band = BandsViewModel.shared.userBands.first(where: { $0.id == bandId }) else {
				print("Band not found")
				// If the band isn't found, return empty variations
				completion([])
				return
			}
			
			group.enter()
			
			// Fetch band members
			BandsViewModel.shared.fetchBandMembers(band, withListener: false) { members in
				group.leave()
				guard let member = members.first(where: { $0.uid == uid }) else {
					print("Member not found")
					// If the member isn't found, return
					completion([])
					return
				}
				
				group.enter()
				BandsViewModel.shared.fetchMemberRoles(band) { roles in
					group.leave()
					guard let memberRoleId = roles.first(where: { $0.id == member.roleId })?.id else {
						print("Member does not have a role")
						completion([])
						return
					}
					
					print("SongService.handVariations: ", "member role ID: ", memberRoleId)
					
					group.enter()
					SongViewModel.shared.fetchSongVariations(song: song, withListener: false) { songVariations in
						// Filter variations based on the role
						for variation in songVariations {
							if let roleId = variation.roleId {
								if roleId == memberRoleId {
									filteredVariations.append(variation)
								}
							}
						}
						
						// If no variations match, add a default variation
						if filteredVariations.isEmpty {
							filteredVariations.append(SongVariation(id: SongVariation.defaultId, title: SongVariation.defaultId, lyrics: "", songUid: "", songId: "", roleId: ""))
						}
						
						group.leave()
					}
				}
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			completion(filteredVariations)
		}
	}
	
	func fetchSong(listen: Bool? = nil, forUser: String? = nil, withId id: String, /* folder: Folder? = nil, */ songCompletion: @escaping (Song?) -> Void, registrationCompletion: @escaping (ListenerRegistration?) -> Void) {
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
					print("Error parsing song or song does not exist (SongService.fetchSong): \(id)")
					songCompletion(nil)
					return
				}
				songCompletion(song)
			}
			registrationCompletion(listenerReg)
		} else {
			documentReference.getDocument { snapshot, error in
				if let error = error {
					print("Error fetching song (SongService.fetchSong) with ID \(id): \(error.localizedDescription)")
					songCompletion(nil)
					registrationCompletion(nil)
					return
				}
				guard let snapshot = snapshot, snapshot.exists, let song = try? snapshot.data(as: Song.self) else {
					print("Error parsing song or song does not exist (SongService.fetchSong): \(id)")
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
				
				completion(folders)
			}
	}
	
	func fetchSongVariations(song: Song, withListener: Bool = true, completion: @escaping([SongVariation]) -> Void) {
		let ref = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations")
		
		if withListener {
			ref.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					return
				}
				let variations = documents.compactMap({ try? $0.data(as: SongVariation.self) })
				
				completion(variations)
			}
		} else {
			ref.getDocuments { snapshot, error in
				guard let documents = snapshot?.documents else {
					return
				}
				let variations = documents.compactMap({ try? $0.data(as: SongVariation.self) })
				
				completion(variations)
			}
		}
	}
	
	func updateBpb(song: Song, bpb: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["bpb": bpb, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateBpm(song: Song, bpm: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["bpm": bpm, "lastEdited": Date()]) { error in
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
		
		ref.updateData(["performanceMode": performanceMode, "lastEdited": Date()]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateTitle(folder: Folder, title: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!)
			.updateData(["title": title, "lastEdited": Date()]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateSong(_ song: Song, title: String, key: String, artist: String, completion: @escaping(Bool, String) -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["title": title, "key": key, "artist": artist, "lastEdited": Date()]) { error in
				if let error = error {
					completion(false, error.localizedDescription)
				} else {
					completion(true, "")
				}
			}
	}
	
	func updateLyrics(forVariation: SongVariation? = nil, song: Song, lyrics: String) {
		if let variation = forVariation {
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!)
				.updateData(["lyrics": lyrics, "lastEdited": Date(), "lastLyricsEdited": Date()]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		} else {
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
				.updateData(["lyrics": lyrics, "lastEdited": Date(), "lastLyricsEdited": Date()]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		}
	}
	
	func updateNotes(song: Song, notes: String) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["notes": notes, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateNotes(folder: Folder, notes: String) {
		Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!)
			.updateData(["notes": notes, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	@discardableResult func fetchNotes(song: Song, completion: @escaping(String) -> Void) -> ListenerRegistration {
		return Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).addSnapshotListener { snapshot, error in
			guard let snapshot = snapshot else { return }
			guard let song = try? snapshot.data(as: Song.self) else { return }
			
			completion(song.notes ?? "")
		}
	}
	
	@discardableResult func fetchNotes(folder: Folder, completion: @escaping(String) -> Void) -> ListenerRegistration {
		return Firestore.firestore().collection("users").document(folder.uid!).collection("folders").document(folder.id!).addSnapshotListener { snapshot, error in
			if let error = error {
				print("Error fetching folder notes with ID \(folder.id!): \(error.localizedDescription)")
				return
			}
			
			guard let folder = try? snapshot?.data(as: Folder.self) else {
				print("Error parsing folder: \(folder.id!)")
				return
			}
			
			completion(folder.notes ?? "")
		}
	}
	
	func updateTextProperties(song: Song, size: Int) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["size": size, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, weight: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["weight": weight, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, lineSpacing: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["lineSpacing": lineSpacing, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateTextProperties(song: Song, alignment: Double) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["alignment": alignment, "lastEdited": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	func updateAutoscrollTimestamps(song: Song, timestamps: [String]) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
			.updateData(["autoscrollTimestamps": timestamps, "lastEdited": Date(), "lastSynced": Date()]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
	}
	
	// UNUSED: will be implemented when folder detail views are created
	/* func createSong(folder: Folder, lyrics: String, artist: String, title: String, key: String, completion: @escaping(Bool, String) -> Void) {
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
	 */
	
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
	
	func createSongVariation(song: Song, lyrics: String, title: String, role: BandRole?, completion: @escaping(Error?, String) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let id = UUID().uuidString
		
		let documentRef = Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(id)
		
		documentRef.setData(["title": title, "lyrics": lyrics, "songUid": uid, "songId": song.id!, "roleId": role?.id ?? FieldValue.delete()]) { error in
			if let error = error {
				print("Error creating song variation: \(error.localizedDescription)")
				completion(error, "")
				return
			}
			
			completion(nil, id)
		}
	}
	
	func createNewDemoAttachment(from url: String, for song: Song, completion: @escaping() -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["demoAttachments": FieldValue.arrayUnion([url]), "lastEdited": Date()]) { error in
				if let error = error {
					print("Error creating song demo attachment: \(error.localizedDescription)")
					completion()
					return
				}
				
				completion()
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
			"tags": song.tags
		]
		
		completion(nil)
		documentRef.setData(songData as [String : Any]) { error in
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
		
		Firestore.firestore().collection("users").document(folder.uid ?? uid).collection("folders").document(folder.id!).collection("songs").document(song.id!).delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func deleteDemoAttachment(demo: DemoAttachment, for song: Song, completion: @escaping() -> Void) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["demoAttachments": FieldValue.arrayRemove([demo.url])]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
				completion()
			}
	}
	
	func deleteVariation(song: Song, variation: SongVariation) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!).delete { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateVariation(song: Song, variation: SongVariation, title: String, role: BandRole?) {
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).collection("variations").document(variation.id!).updateData(["title": title, "roleId": role?.id ?? FieldValue.delete()]) { error in
			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
	
	func updateDemo(for song: Song, oldUrl: String, url: String, completion: @escaping() -> Void) {
		if let demoAttachments = song.demoAttachments, demoAttachments.contains(oldUrl) {
			Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
				.updateData(["demoAttachments": FieldValue.arrayRemove([oldUrl])]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
				}
		}
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!)
			.updateData(["demoAttachments": FieldValue.arrayUnion([url])]) { error in
				if let error = error {
					print(error.localizedDescription)
				}
			}
		completion()
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
	/*
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
	 */
	
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
			"tags": song.tags
		]
		
		Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id!).setData(songData as [String : Any]) { error in
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
		let songData: [String: Any?] = [
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
			"tags": song.tags
		]
		
		let firestore = Firestore.firestore()
		let userRef = firestore.collection("users").document(song.uid)
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
		
		recentlyDeletedRef.setData(songData as [String : Any]) { error in
			if let error = error {
				completion(false, error.localizedDescription)
			} else {
				completion(true, nil)
			}
		}
	}
	
	func moveSongsToFolder(_ folder: Folder, songs: [Song], completion: @escaping(Error?) -> Void) {
		guard let userId = Auth.auth().currentUser?.uid else { return }
		
		let songsCollectionRef = Firestore.firestore().collection("users").document(folder.uid ?? userId).collection("folders").document(folder.id!).collection("songs")
		
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
		let filteredTags = tags.map { $0.rawValue }
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).updateData(["tags": filteredTags.isEmpty ? FieldValue.delete() : filteredTags], completion: completion)
	}
	
	func sendInviteToUser(request: ShareRequest, users: [ShareUser], includeDefault: Bool, completion: @escaping(Error?) -> Void) {
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
			"bandId": request.bandId,
			"notificationTokens": request.notificationTokens,
			"fromNotificationToken": request.fromNotificationToken
		]
		
		Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(id).setData(requestData as [String : Any]) { error in
			if let error = error {
				completion(error)
				print(error.localizedDescription)
				return
			}
			
			for user in users {
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
					"songVariations": user.songVariations,
					"readOnly": request.readOnly,
					"bandId": request.bandId
				]
				
				dispatch.enter()
				Firestore.firestore().collection("users").document(user.uid).collection("incoming-share-requests").document(id).setData(requestData as [String : Any]) { error in
					if let error = error {
						completion(error)
						print(error.localizedDescription)
					}
					dispatch.leave()
					if let currentUser = AuthViewModel.shared.currentUser, let token = user.fcmId {
						UserService().sendNotificationToFCM(tokens: [token], title: "Incoming Request", body: "\(currentUser.username) has sent a \(request.contentType == "folder" ? "folder" : "song").", type: .incoming)
					}
				}
			}
			
			dispatch.notify(queue: .main) {
				if let currentUser = AuthViewModel.shared.currentUser, let tokens = request.notificationTokens {
					UserService().sendNotificationToFCM(tokens: tokens, title: "Incoming Request", body: "\(currentUser.fullname) has shared a \(request.contentType == "folder" ? "folder" : "song")", type: .incoming)
				}
				if let bandId = request.bandId {
					Firestore.firestore().collection("users").document(request.from).collection("songs").document(id).updateData(["bandId": bandId])
				}
				Firestore.firestore().collection("users").document(request.from).collection("songs").document(id).updateData(["joinedUsers": FieldValue.arrayUnion([request.from])])
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
	
	func declineInvite(incomingReqColUid: String? = nil, request: ShareRequest, declinedBy: String? = nil, completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let group = DispatchGroup()
		
		group.enter()
		deleteRequest(if: request, uid: incomingReqColUid ?? uid)
		group.leave()
		
		group.notify(queue: .main) {
			if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
				if let declinedBy = declinedBy {
					if declinedBy != request.from {
						UserService().sendNotificationToFCM(tokens: [token], title: "Request Declined", body: "\(currentUser.fullname) has declined the \(request.contentType == "folder" ? "folder" : "song") \"\(request.contentName)\"", type: .declined)
					}
				} else {
					UserService().sendNotificationToFCM(tokens: [token], title: "Request Declined", body: "\(currentUser.fullname) has declined the \(request.contentType == "folder" ? "folder" : "song") \"\(request.contentName)\"", type: .declined)
				}
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
						let sharedFolder: [String: Any?] = [
							"from": request.from,
							"folderId": request.contentId,
							"order": 0,
							"readOnly": request.readOnly ?? false,
							"songVariations": request.songVariations,
							"bandId": request.bandId
						]
						
						dispatch.enter()
						Firestore.firestore().collection("users").document(uid).collection("shared-folders").document(folder.id!).setData(sharedFolder as [String : Any]) { error in
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
							Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id!).updateData(["to": FieldValue.arrayRemove([uid])])
							self.deleteRequest(if: request, uid: uid)
							completion()
						}
					} else {
						dispatch.enter()
						self.createFolder(folder: folder, id: request.contentId) { error in
							if let error = error {
								print("Error: \(error.localizedDescription)")
							}
							dispatch.leave()
						}
						
						dispatch.enter()
						self.fetchSongs(forUid: request.from, folder) { folderSongs in
							for song in folderSongs {
								var songToAdd = song
								songToAdd.uid = uid
								
								self.createSong(song: songToAdd) { error in
									if let error = error {
										print(error.localizedDescription)
									}
									songs.append(songToAdd)
								}
							}
							
							self.moveSongsToFolder(folder, songs: songs) { error in
								if let error = error {
									print(error.localizedDescription)
								}
							}
							dispatch.leave()
						}
						
						dispatch.notify(queue: .main) {
							if let currentUser = AuthViewModel.shared.currentUser, let tokens = request.notificationTokens {
								UserService().sendNotificationToFCM(tokens: tokens, title: "Request Accepted", body: "\(currentUser.username) has accepted the folder \"\(request.contentName)\".", type: .accepted)
								
								if request.to.count > 1 {
									for toUser in request.to {
										Firestore.firestore().collection("users").document(toUser).collection("incoming-share-requests").document(request.id!).updateData(["to": FieldValue.arrayRemove([uid])]) { error in
											if let error = error {
												print(error.localizedDescription)
											}
											self.deleteRequest(request, uid: uid, outgoing: false)
										}
									}
								} else {
									self.deleteRequest(request, uid: uid)
								}
							}
							self.deleteRequest(request, uid: uid)
							if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
								UserService().sendNotificationToFCM(tokens: [token], title: "Request Accepted", body: "\(currentUser.fullname) has accepted the folder \"\(request.contentName)\"", type: .accepted)
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
						"readOnly": request.readOnly,
						"variations": request.songVariations,
						"bandId": request.bandId
					]
					
					dispatch.enter()
					Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id!).setData(sharedSong as [String : Any]) { error in
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
						self.deleteRequest(if: request, uid: uid)
						if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
							UserService().sendNotificationToFCM(tokens: [token], title: "Request Accepted", body: "\(currentUser.fullname) has accepted the song \"\(request.contentName)\"", type: .accepted)
						}
						completion()
					}
				} else {
					var songData: [String: Any?] = [
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
						"performanceMode": song.performanceMode
					]
					
					if AuthViewModel.shared.currentUser?.hasPro != nil {
						songData["demoAttachments"] = song.demoAttachments ?? []
					}
					
					let id = UUID().uuidString
					
					dispatch.enter()
					Firestore.firestore().collection("users").document(uid).collection("songs").document(id).setData(songData as [String : Any]) { error in
						if let error = error {
							print(error.localizedDescription)
						}
						dispatch.leave()
					}
					dispatch.enter()
					Firestore.firestore().collection("users").document(request.from).collection("songs").document(song.id!).collection("variations").getDocuments { snapshot, error in
						dispatch.leave()
						guard let documents = snapshot?.documents else { return }
						let variations = documents.compactMap({ try? $0.data(as: SongVariation.self )})
						
						for variation in variations {
							dispatch.enter()
							Firestore.firestore().collection("users").document(uid).collection("songs").document(id).collection("variations").document(variation.id ?? "").setData(["lyrics": variation.lyrics, "songId": variation.songId, "songUid": variation.songUid, "title": variation.title]) { error in
								if let error = error {
									print(error.localizedDescription)
								}
								dispatch.leave()
							}
						}
						
						dispatch.notify(queue: .main) {
							self.deleteRequest(request, uid: uid)
							if let currentUser = AuthViewModel.shared.currentUser, let token = request.fromNotificationToken {
								UserService().sendNotificationToFCM(tokens: [token], title: "Request Accepted", body: "\(currentUser.fullname) has accepted the song \"\(request.contentName)\"", type: .accepted)
							}
							completion()
						}
					}
				}
			} registrationCompletion: { _ in }
		}
	}
	
	func deleteRequest(_ request: ShareRequest, uid: String, outgoing: Bool? = nil) {
		Firestore.firestore().collection("users").document(uid).collection("incoming-share-requests").document(request.id!).delete { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				return
			}
		}
		if outgoing ?? true {
			Firestore.firestore().collection("users").document(request.from).collection("outgoing-share-requests").document(request.id!).delete { error in
				if let error = error {
					print("Error: \(error.localizedDescription)")
					return
				}
			}
		}
	}
	
	func deleteRequest(if request: ShareRequest, uid userId: String) {
		if request.to.count <= 1 {
			self.deleteRequest(request, uid: userId)
		} else {
			for toUser in request.to {
				Firestore.firestore().collection("users").document(toUser).collection("incoming-share-requests").document(request.id!).updateData(["to": FieldValue.arrayRemove([userId])]) { error in
					if let error = error {
						print(error.localizedDescription)
					}
					self.deleteRequest(request, uid: userId, outgoing: false)
				}
			}
			if userId == uid() {
				self.deleteRequest(request, uid: userId)
			}
		}
	}
	
	func leaveCollabSong(forUid: String? = nil, song: Song, completion: @escaping() -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let dispatch = DispatchGroup()
		
		dispatch.enter()
		Firestore.firestore().collection("users").document(forUid ?? uid).collection("shared-songs").document(song.id!).delete { error in
			dispatch.leave()
			if let error = error {
				print(error.localizedDescription)
			}
		}
		
		dispatch.enter()
		Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).updateData(["joinedUsers": FieldValue.arrayRemove([forUid ?? uid])]) { error in
			dispatch.leave()
			if let error = error {
				print(error.localizedDescription)
			}
		}
		
		dispatch.notify(queue: .main) {
			if song.bandId != nil {
				guard let joinedUsers = {
					return song.joinedUsers?.filter { userId in
						userId != uid
					}
				}() else { return }
				
				if joinedUsers.count <= 1 {
					Firestore.firestore().collection("users").document(song.uid).collection("songs").document(song.id!).updateData(["bandId": FieldValue.delete()])
				}
			}
			UserService().fetchUser(withUid: forUid ?? song.uid) { user in
				if let currentUser = AuthViewModel.shared.currentUser, let token = user.fcmId {
					UserService().sendNotificationToFCM(tokens: [token], title: "Song Left", body: "\(currentUser.fullname) has left the song \"\(song.title)\"", type: .left)
				}
				completion()
			}
		}
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
			UserService().fetchUser(withUid: forUid ?? (folder.uid ?? "")) { user in
				if let currentUser = AuthViewModel.shared.currentUser, let token = user.fcmId {
					UserService().sendNotificationToFCM(tokens: [token], title: "Folder Left", body: "\(currentUser.fullname) has left the folder \"\(folder.title)\"", type: .left)
				}
				completion()
			}
		}
	}
}
