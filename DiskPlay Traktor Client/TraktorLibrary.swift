//
//  TraktorLibrary.swift
//  DiskPlay Traktor Client
//
//  Created by Florian Heller on 12.07.17.
//  Copyright © 2017 Florian Heller - UHasselt. All rights reserved.
//

import Cocoa
import SWXMLHash

struct TraktorTrack {
	let title: String
	let artist: String
	let fileLocation: URL
	let cuePoints: [Date]
	let TrackID: String
	
}

class TraktorLibrary: NSObject {

	var trackCollection:[TraktorTrack] = []
	
	override init() {
		super.init()
		trackCollection = loadCollection(url: URL.init(fileURLWithPath: "/Users/heller/Documents/Native Instruments/Traktor 2.11.0/collection.nml"))
		print(trackCollection)
	}
	
	func loadCollection(url:URL) -> [TraktorTrack] {
		
		var result:[TraktorTrack] = []
		let data:String?
		do {
			data = try String.init(contentsOf: url)
		}
		catch {
			print("Unable to load Traktor Library")
			return []
		}
		
		let xml = SWXMLHash.parse(data!)

		for entry in xml["NML"]["COLLECTION"]["ENTRY"].all {
			let title = entry.value(ofAttribute: "TITLE") ?? ""
			let artist = entry.value(ofAttribute: "ARTIST") ?? ""
			let url = URL.init(fileURLWithPath: entry["LOCATION"].value(ofAttribute: "DIR") ?? "")
			
			let track = TraktorTrack.init(title: title,
			                              artist: artist,
			                              fileLocation: url,
			                              cuePoints: [],
			                              TrackID: "")
			result.append(track)
		}
		
		return result
	}
	
}
