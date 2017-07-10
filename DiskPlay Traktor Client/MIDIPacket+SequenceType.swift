//
//  MIDIPacket+SequenceType.swift
//  DiskPlay Traktor Client
//
//	Taken from https://github.com/jverkoey/swift-midi/blob/master/LUMI/CoreMIDI/MIDIPacket%2BSequenceType.swift

import CoreMIDI

/** The returned generator will enumerate each value of the provided tuple. */
func generatorForTuple(tuple: Any) -> AnyIterator<Any> {
	let children = Mirror(reflecting: tuple).children
	return AnyIterator(children.makeIterator().lazy.map { $0.value }.makeIterator())
}

//struct MIDIPacketIterator: IteratorProtocol {
//	
//}




/**
Allows a MIDIPacket to be iterated through with a for statement.
Example usage:
let packet: MIDIPacket
for message in packet {
// message is a Message
}
*/
extension MIDIPacket: Sequence {
//	func makeIterator() -> MIDIPacketIterator {
//		return MIDIPacketIterator(self.data)
//	}
//	
	
	
	
	public func makeIterator() -> AnyIterator<Event> {
		let generator = generatorForTuple(tuple: self.data)
		var index: UInt16 = 0
		
		return AnyIterator {
			if index >= self.length {
				return nil
			}
			
			func pop() -> UInt8 {
				assert(index < self.length)
				index += 1
				return generator.next() as! UInt8
			}
			
			let status = pop()
			if Message.isStatusByte(byte: status) {
				var data1: UInt8 = 0
				var data2: UInt8 = 0
				
				switch Message.statusMessage(byte: status) {
				case .NoteOff: data1 = pop(); data2 = pop();
				case .NoteOn: data1 = pop(); data2 = pop();
				case .Aftertouch: data1 = pop(); data2 = pop();
				case .ControlChange: data1 = pop(); data2 = pop();
				case .ProgramChange: data1 = pop()
				case .ChannelPressure:data1 = pop()
				case .PitchBend: data1 = pop(); data2 = pop();
				}
				
				return Event(timeStamp: self.timeStamp, status: status, data1: data1, data2: data2)
			}
			
			return nil
		}
	}
}
