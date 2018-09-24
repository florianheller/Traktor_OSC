//
//  MidiController.swift
//  CrossMix
//
//  Created by Florian Heller on 15/11/2016.
//  Copyright © 2016 Florian Heller - UHasselt. All rights reserved.
//

import Cocoa
import CoreMIDI

class MidiController: NSObject,DisplayDecoderDelegate {
	
	
	// Midi connection details
	var midiInputClient = MIDIClientRef()
	var midiClient = MIDIClientRef()
	var midiOutput = MIDIPortRef()
	var midiInput = MIDIPortRef()
	var traktorOutput = MIDIEndpointRef()
	var traktorInput = MIDIEndpointRef()
	
	var midiMessageQueue:DispatchQueue = DispatchQueue.init(label: "DiskPlayMIDI")
	
	// Other settings
	let numberOfChannelsPerDeck = 25
	let startChannelDeckA = 27
	let startChannelDeckB = 52
	let diskPlayMidiController = 0xBF
	
	var displayDecoderA = DisplayDecoder(deck:TraktorDeck.A)
	weak var viewController:ViewController?
	
	//MARK:Object Lifecycle
	override init() {
		super.init()
		
		// Get hold of the Traktor Virtual Output
		let sourceCount = MIDIGetNumberOfSources()
		for i in 0...sourceCount {
			let device = MIDIGetSource(i)
			var sourceName:Unmanaged<CFString>?
			var status = MIDIObjectGetStringProperty(device, kMIDIPropertyDisplayName , &sourceName)
			// Make sure that we have succesfully read the property
			guard status == noErr else { continue }
			print(sourceName!.takeUnretainedValue() as String)
			
			// We are looking for the Traktor Virtual Midi ouput only
			if ((sourceName!.takeUnretainedValue() as String) == "Traktor Virtual Output") {
				print("Found Traktor Output")
				self.traktorOutput = device
				MIDIClientCreateWithBlock("CrossMix MIDI" as CFString, &midiInputClient, midiNotifyBlock)
				
				guard status == noErr else { continue }
				
				status = MIDIInputPortCreateWithBlock(midiInputClient, "CrossMix MIDI Input" as CFString, &midiInput, midiReadBlock)
				status = MIDIPortConnectSource(midiInput, traktorOutput, nil)
					break // If we found what we're looking for, just stop
			}
		}
		
		
		
		let destinationCount = MIDIGetNumberOfDestinations()
		for i in 0...destinationCount {
			let device = MIDIGetDestination(i)
			var sourceName:Unmanaged<CFString>?
			var status = MIDIObjectGetStringProperty(device, kMIDIPropertyDisplayName , &sourceName)
			// Make sure that we have succesfully read the property
			guard status == noErr else { continue }
			print(sourceName!.takeUnretainedValue() as String)
			// We are looking for the Traktor Virtual Midi ouput only
			if ((sourceName!.takeUnretainedValue() as String) == "Traktor Virtual Input") {
				print("Found Traktor Input")
				self.traktorInput = device
				
				status = MIDIClientCreateWithBlock("CrossMix MIDI" as CFString, &midiClient, midiNotifyBlock)
				
				guard status == noErr else { continue }
				
				status = MIDIOutputPortCreate(midiClient, "CrossMix MIDI Output" as CFString, &midiOutput)
				guard status == noErr else { continue }
				
				
			
				break // If we found what we're looking for, just stop
			}
			
		}
		
		displayDecoderA.delegate = self
		
	}
	
	deinit {
		MIDIEndpointDispose(self.traktorInput)
		MIDIEndpointDispose(self.traktorOutput)
		MIDIClientDispose(self.midiClient)
		MIDIClientDispose(self.midiInputClient)
		MIDIPortDispose(self.midiOutput)
	}
	

	//MARK: Receive Blocks/Callbacks
	//typealias MIDINotifyBlock = (UnsafePointer<MIDINotification>) -> Void
	func midiNotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
		print("Notification")
	}
	
	//typealias MIDIReadBlock = (UnsafePointer<MIDIPacketList>, UnsafeMutableRawPointer?) -> Void
	///The reception block whenever a new MIDI packet arrives
	/// - parameter midiPackets: A list of MIDI packets
	/// - parameter additional: An optional additional pointer
	func midiReadBlock(midiPacketList:UnsafePointer<MIDIPacketList>, additional: UnsafeMutableRawPointer?) {
		let packets = midiPacketList.pointee
		let packet:MIDIPacket = packets.packet
		
		var currentPacket = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
		currentPacket.initialize(to:packet)
		
		for _ in 0 ..< packets.numPackets {
			let p = currentPacket.pointee
			processPacket(packet: p)
			currentPacket = MIDIPacketNext(currentPacket)
		}
	}


	//MARK: Packet processing


	func processPacket(packet: MIDIPacket) {
		
		//Iterate over this for all controller data in the midi packet
		

		for message in packet {
			// The Denon stuff goes to the display decoder
			if (message.status == 0xB0 || message.status == 0xB1) {
				
				if (viewController != nil) {
					switch ( message.data1 ) {
					case 0x01: viewController?.updateByte(msb: true, segment: 0, value: message.data2);
					case 0x02: viewController?.updateByte(msb: true, segment: 1, value: message.data2);
					case 0x03: viewController?.updateByte(msb: true, segment: 2, value: message.data2);
					case 0x04: viewController?.updateByte(msb: true, segment: 3, value: message.data2);
					case 0x05: viewController?.updateByte(msb: true, segment: 4, value: message.data2);
					case 0x07: viewController?.updateByte(msb: true, segment: 5, value: message.data2);
					case 0x08: viewController?.updateByte(msb: true, segment: 6, value: message.data2);
					case 0x09: viewController?.updateByte(msb: true, segment: 7, value: message.data2);
					case 0x0A: viewController?.updateByte(msb: true, segment: 8,  value: message.data2);
					case 0x0B: viewController?.updateByte(msb: true, segment: 9, value: message.data2);
					case 0x0C: viewController?.updateByte(msb: true, segment: 10, value: message.data2);
					case 0x0D: viewController?.updateByte(msb: true, segment: 11, value: message.data2);
						
					case 0x21: viewController?.updateByte(msb: false, segment: 0, value: message.data2);
					case 0x22: viewController?.updateByte(msb: false, segment: 1, value: message.data2);
					case 0x23: viewController?.updateByte(msb: false, segment: 2, value: message.data2);
					case 0x24: viewController?.updateByte(msb: false, segment: 3, value: message.data2);
					case 0x25: viewController?.updateByte(msb: false, segment: 4, value: message.data2);
					case 0x27: viewController?.updateByte(msb: false, segment: 5, value: message.data2);
					case 0x28: viewController?.updateByte(msb: false, segment: 6, value: message.data2);
					case 0x29: viewController?.updateByte(msb: false, segment: 7, value: message.data2);
					case 0x2A: viewController?.updateByte(msb: false, segment: 8, value: message.data2);
					case 0x2B: viewController?.updateByte(msb: false, segment: 9, value: message.data2);
					case 0x2C: viewController?.updateByte(msb: false, segment: 10, value: message.data2);
					case 0x2D: viewController?.updateByte(msb: false, segment: 11, value: message.data2);
					default: break
					}
				}
				//TODO: split this on two displaydecoders for deck A and B
				displayDecoderA.midiProc(channel: message.data1, value: message.data2)
				//return
			}
		}
		
		

	}
	
	//MARK:Sending
	/// Send a MIDI CC Message
	/// - parameter channel: The channel on which the message should be sent
	/// - parameter controller: The controller to receive the sent value
	/// - parameter value: The actual value to be sent
	func sendMidiControlMessage(channel: UInt8, controller: UInt8, value: UInt8) {
		var packet = MIDIPacket()
		packet.timeStamp = 0
		packet.length = 3
		packet.data.0 = channel
		packet.data.1 = controller;
		packet.data.2 = value;
		
		var packets = MIDIPacketList(numPackets: 1, packet: packet)
		
		MIDISend(midiOutput, traktorInput, &packets)
	}
	
	func setMonitorMixer(value:Int) {
		let v = UInt8(value)
		sendMidiControlMessage(channel: 0xBF, controller: 0x64, value: v )
	}
	
	//MARK: DisplayDecoder delegate
	func trackInfoWasDecoded(title:String, artist:String, deck:TraktorDeck)
	{
		print(title)
		print(artist)
	}

	
}
