//
//  DisplayDecoder.swift
//  DiskPlay Traktor Client
//
//  Created by Florian Heller on 16/11/2016.
//  Copyright © 2016 Florian Heller - UHasselt. All rights reserved.
//
//	Based on the script by Bernd Konnerth <Bernd@konnerth.de>
import Cocoa

enum TraktorDeck {
	case DeckA
	case DeckB
	case DeckC
	case DeckD
}

enum DispalyType:Int {
	case title = 0, artist
}

protocol DisplayDecoderDelegate {
	func trackInfoWasDecoded(title:String, artist:String, deck:TraktorDeck)
}

class DisplayDecoder: NSObject {

	var delegate:DisplayDecoderDelegate?
	var deck = TraktorDeck.DeckA
//	var active_element;
//	var current_in;
//	var track;
//	var sel;
	var MSB_0:UInt8? = 0;
	var LSB_0:UInt8? = 0;
	var WAIT_LSB_0 = 0;
	var MSB_1:UInt8? = 0;
	var LSB_1:UInt8? = 0;
	var WAIT_LSB_1 = 0;
	var line  = -1;
	var tmp_pos = 0;
	
	var playing_A = false;
	var play_A_1 = false;
	var play_A_2 = false;
	var stop_A_1 = false;
	var stop_A_2 = false;
	var played_A_sent = false;
	
	var playing_B = false;
	var play_B_1 = false;
	var play_B_2 = false;
	var stop_B_1 = false;
	var stop_B_2 = false;
	var played_B_sent = false;
	
	var last_time_stamp_deck_A: Date?
	var last_time_stamp_deck_B: Date?
	
	var time_count_A = 0.0;
	var time_count_B = 0.0;
	
	var pos        = [   -1,   -1,   -1,   -1 ]
	var last_pos   = [    0,    0,    0,    0 ]
	var new11      = [    0,    0,    0,    0 ]
	var line_complete = [    0,    0,    0,    0 ]
	//var line_elem  = [ null, null, null, null ]
	var char_complete = false
	var str = String()
	var reset_once = [ false, false, false, false ]
	
	var line_char_array = [  [ "","","","","","","","","","","","" ],
	[ "","","","","","","","","","","","" ],
	[ "","","","","","","","","","","","" ],
	[ "","","","","","","","","","","","" ] ]
	
	var line_static_str_VISUAL = [ "", "", "", "" ]
	var line_static_str        = [ "", "", "", "" ]
	var line_static_str_SHADOW = [ "", "", "", "" ]
	
	func removeMultipleUnderscores (aString:String) -> String {
		var str = aString.replacingOccurrences(of: "__", with: "_")
		str = str.replacingOccurrences(of: "___", with: "_")
		return str
	}
	
	init(deck:TraktorDeck) {
		self.deck = deck
	}
	
	// Identical characters following each other are not written by Traktors algorithm!!! Instead Traktor
	// obviously expects the controller to fill these spaces automatically up to the next, officially by
	// Traktor written position, with the same character.
	//
	// Will Survive
	// *
	//  *
	//   *
	// Notice this gap! The position for this "l" is not written by Traktor because it expects the controller to fill it with an "l"
	//     *
	//      *
	//       ......
	// FillUnwrittenChars() performs this mechanism
	func fillUnwrittenChars( inString:String, lineIndex:Int ) {
		line_char_array[lineIndex][pos[lineIndex]] = inString;
		if ( pos[lineIndex] - last_pos[lineIndex] > 1 && line_char_array[lineIndex][last_pos[lineIndex]] != "_" ) {
				while ( last_pos[lineIndex] < pos[lineIndex] - 1 ) {
					line_char_array[lineIndex][last_pos[lineIndex] + 1] = line_char_array[lineIndex][last_pos[lineIndex]]
					last_pos[lineIndex]=last_pos[lineIndex]+1;
				}
			}
			else if ( pos[lineIndex] < last_pos[lineIndex] && last_pos[lineIndex] < 11 && line_char_array[lineIndex][last_pos[lineIndex]] != "_") {
				while ( last_pos[lineIndex] < 11 ) {
					line_char_array[lineIndex][last_pos[lineIndex] + 1] = line_char_array[lineIndex][last_pos[lineIndex]]
					last_pos[lineIndex]=last_pos[lineIndex]+1;
					
					if ( last_pos[lineIndex] == 11 ) {
						new11[lineIndex] = 1;
					}
				}
			
				if ( pos[lineIndex] > 0 ) {
					last_pos[lineIndex] = 0;
				
					while ( last_pos[lineIndex] < pos[lineIndex] - 1 ) {
						line_char_array[lineIndex][last_pos[lineIndex] + 1] = line_char_array[lineIndex][last_pos[lineIndex]]
						last_pos[lineIndex]=last_pos[lineIndex]+1;
					}
				}
			}
		
		if ( pos[lineIndex] == 11 ) {
			new11[lineIndex] = 1;
		}
		
		last_pos[lineIndex] = pos[lineIndex];

	}
	
	
	func findStart(lineIndex: Int) {
		line_static_str_SHADOW[lineIndex] = line_char_array[lineIndex].joined(separator: "")
		// Make a String out of the elements we have
		// If we have three blanks somewhere in the string
		if (line_static_str_SHADOW[lineIndex].contains("   ")) {
			// Remove trailing blanks
			line_static_str_SHADOW[lineIndex] = line_static_str_SHADOW[lineIndex].trimmingCharacters(in: CharacterSet.whitespaces)
			// If there are multiple underscores due to german "Umlaute" reduce every multiple to one underscore
			line_static_str_SHADOW[lineIndex] = removeMultipleUnderscores(aString: line_static_str_SHADOW[lineIndex])
			//print(line_static_str_SHADOW[0])
			print(line_static_str_VISUAL[lineIndex] + " | "  + line_static_str[lineIndex] + " | " + line_static_str_SHADOW[lineIndex] + " | " +  line_char_array[lineIndex].joined(separator: "") );
			// String not final yet, due to marker confusion?
			if ( line_static_str[lineIndex] != line_static_str_SHADOW[lineIndex] ) {
								line_static_str[lineIndex] = line_static_str_SHADOW[lineIndex];
								line_complete[lineIndex] = 0;
			}
			else {
				line_complete[lineIndex] = 1;
				// If line 0 has been completed reset line 1 once to ensure that track an artist match. Otherwise a track could get the wrong artist!
				if ( lineIndex == 0 ) {
					if ( reset_once[1] == false ) {
						line_complete[1] = 0;
						reset_once[1] = true;
					}
					else {
						reset_once[1] = false;
					}
				}

				// If line 1 has been completed reset line 0 once to ensure that track an artist match. Otherwise a track could get the wrong artist!
				if ( lineIndex == 1 ) {
					if ( reset_once[0] == false ) {
						line_complete[0] = 0;
						reset_once[0] = true;
					}
					else {
						reset_once[0] = false;
					}
				}

				// If line 2 has been completed reset line 3 once to ensure that track an artist match. Otherwise a track could get the wrong artist!
				if ( lineIndex == 2 ) {
					if ( reset_once[3] == false ) {
						line_complete[3] = 0;
						reset_once[3] = true;
					}
					else {
						reset_once[3] = false;
					}
				}

				// If line 3 has been completed reset line 2 once to ensure that track an artist match. Otherwise a track could get the wrong artist!
				if ( lineIndex == 3 ) {
					if ( reset_once[2] == false ) {
						line_complete[2] = 0;
						reset_once[2] = true;
					}
					else {
						reset_once[2] = false;
					}
				}
				print(line_static_str_VISUAL[0])
				if (line_complete[0] == 1 &&
					line_complete[1] == 1 &&
					( line_static_str_VISUAL[0] != line_static_str[0] ||
						line_static_str_VISUAL[1] != line_static_str[1])
					) {
						line_static_str_VISUAL[0] = line_static_str[0];
						line_static_str_VISUAL[1] = line_static_str[1];
					
						delegate?.trackInfoWasDecoded(title: line_static_str[0], artist: line_static_str[1], deck: .DeckA)
						line_complete[0] = 0;
						line_complete[1] = 0;
				}
				else if (line_complete[2] == 1 &&
						line_complete[3] == 1 &&
						( line_static_str_VISUAL[2] != line_static_str[2] ||
							line_static_str_VISUAL[3] != line_static_str[3])
					) {
						line_static_str_VISUAL[2] = line_static_str[2];
						line_static_str_VISUAL[3] = line_static_str[3];
					delegate?.trackInfoWasDecoded(title: line_static_str[0], artist: line_static_str[1], deck: .DeckB)
					line_complete[0] = 0;
					line_complete[1] = 0;
					line_complete[2] = 0;
					line_complete[3] = 0;
				}
			}

			line_static_str_SHADOW[lineIndex] = "";
		}
		else {
			if ( new11[lineIndex] == 1 ) {
				line_static_str_SHADOW[lineIndex] += line_char_array[lineIndex][11];
				new11[lineIndex] = 0;
			}
		}
	}
	
	// Callback function
	// Timestamp, three bytes
	//func midiProc ( a: UInt8, b: UInt8, c: UInt8 ) {
	func midiProc(channel:UInt8, value:UInt8) {

		switch ( channel ) {
			case 0x01: line = 0; tmp_pos = 0; MSB_0 = value; 
			case 0x02: line = 0; tmp_pos = 1; MSB_0 = value; 
			case 0x03: line = 0; tmp_pos = 2; MSB_0 = value; 
			case 0x04: line = 0; tmp_pos = 3; MSB_0 = value;
			case 0x05: line = 0; tmp_pos = 4; MSB_0 = value; 
			case 0x07: line = 0; tmp_pos = 5; MSB_0 = value; 
			case 0x08: line = 0; tmp_pos = 6; MSB_0 = value; 
			case 0x09: line = 0; tmp_pos = 7; MSB_0 = value; 
			case 0x0A: line = 0; tmp_pos = 8; MSB_0 = value; 
			case 0x0B: line = 0; tmp_pos = 9; MSB_0 = value; 
			case 0x0C: line = 0; tmp_pos = 10;MSB_0 = value; 
			case 0x0D: line = 0; tmp_pos = 11;MSB_0 = value; 

			case 0x21: line = 0; tmp_pos = 0; LSB_0 = value; 
			case 0x22: line = 0; tmp_pos = 1; LSB_0 = value; 
			case 0x23: line = 0; tmp_pos = 2; LSB_0 = value; 
			case 0x24: line = 0; tmp_pos = 3; LSB_0 = value; 
			case 0x25: line = 0; tmp_pos = 4; LSB_0 = value; 
			case 0x27: line = 0; tmp_pos = 5; LSB_0 = value; 
			case 0x28: line = 0; tmp_pos = 6; LSB_0 = value; 
			case 0x29: line = 0; tmp_pos = 7; LSB_0 = value; 
			case 0x2A: line = 0; tmp_pos = 8; LSB_0 = value; 
			case 0x2B: line = 0; tmp_pos = 9; LSB_0 = value; 
			case 0x2C: line = 0; tmp_pos = 10;LSB_0 = value; 
			case 0x2D: line = 0; tmp_pos = 11;LSB_0 = value;
	
			case 0x0E: line = 1; tmp_pos = 0; MSB_1 = value; 
			case 0x0F: line = 1; tmp_pos = 1; MSB_1 = value; 
			case 0x10: line = 1; tmp_pos = 2; MSB_1 = value; 
			case 0x11: line = 1; tmp_pos = 3; MSB_1 = value; 
			case 0x12: line = 1; tmp_pos = 4; MSB_1 = value; 
			case 0x13: line = 1; tmp_pos = 5; MSB_1 = value; 
			case 0x14: line = 1; tmp_pos = 6; MSB_1 = value; 
			case 0x15: line = 1; tmp_pos = 7; MSB_1 = value; 
			case 0x16: line = 1; tmp_pos = 8; MSB_1 = value; 
			case 0x17: line = 1; tmp_pos = 9; MSB_1 = value; 
			case 0x18: line = 1; tmp_pos = 10;MSB_1 = value; 
			case 0x19: line = 1; tmp_pos = 11;MSB_1 = value; 

			case 0x2E: line = 1; tmp_pos = 0; LSB_1 = value; 
			case 0x2F: line = 1; tmp_pos = 1; LSB_1 = value; 
			case 0x30: line = 1; tmp_pos = 2; LSB_1 = value; 
			case 0x31: line = 1; tmp_pos = 3; LSB_1 = value; 
			case 0x32: line = 1; tmp_pos = 4; LSB_1 = value; 
			case 0x33: line = 1; tmp_pos = 5; LSB_1 = value; 
			case 0x34: line = 1; tmp_pos = 6; LSB_1 = value; 
			case 0x35: line = 1; tmp_pos = 7; LSB_1 = value; 
			case 0x36: line = 1; tmp_pos = 8; LSB_1 = value; 
			case 0x37: line = 1; tmp_pos = 9; LSB_1 = value; 
			case 0x38: line = 1; tmp_pos = 10;LSB_1 = value; 
			case 0x39: line = 1; tmp_pos = 11;LSB_1 = value;
			
			default:
				print("%d %d", channel, value)
				line  = -1;
				tmp_pos  = -1;
				return
			}
		char_complete = false;

		// Check if LSB_0 received
		if ( MSB_0 != nil && LSB_0 == nil ) {
			if ( WAIT_LSB_0 == 1 ) {
				print( "ERROR: LSB_0 not received!");
				MSB_0 = nil;
				WAIT_LSB_0 = 0;
			}
			else {
				WAIT_LSB_0 = 1;
			}
		}

		// Check if MSB_0 received
		if ( MSB_0 == nil && LSB_0 != nil ) {
			print( "ERROR: MSB_0 not received!");
			LSB_0 = nil;
		}

		if ( MSB_0 != nil && LSB_0 != nil ) {
			str = String(Character(UnicodeScalar(((MSB_0! << 4) | LSB_0!))))
			MSB_0 = nil;
			LSB_0 = nil;
			WAIT_LSB_0 = 0;
			char_complete = true;
		}

		// Check if LSB_1 received
		if ( MSB_1 != nil && LSB_1 == nil ) {
			if ( WAIT_LSB_1 == 1 ) {
				print( "ERROR: LSB_1 not received!");
				MSB_1 = nil;
				WAIT_LSB_1 = 0;
			}
			else {
				WAIT_LSB_1 = 1;
			}
		}

		// Check if MSB_1 received
		if ( MSB_1 == nil && LSB_1 != nil) {
			print( "ERROR: MSB_1 not received!");
			LSB_1 = nil;
		}

		if ( MSB_1 != nil && LSB_1 != nil ) {
			str = String(Character(UnicodeScalar(((MSB_1! << 4) | LSB_1!))))
			MSB_1 = nil;
			LSB_1 = nil;
			WAIT_LSB_1 = 0;
			char_complete = true;
		}

		guard char_complete != false else { return }

		if ( line == 0 ) {// Line 1
			pos[0] = tmp_pos;
			fillUnwrittenChars ( inString: str, lineIndex: 0 );
			findStart ( lineIndex: 0 );
		} else { // Line 2
			pos[1] = tmp_pos;
			fillUnwrittenChars ( inString: str, lineIndex: 1 );
			findStart ( lineIndex: 1 );
		}
	}
	
}
