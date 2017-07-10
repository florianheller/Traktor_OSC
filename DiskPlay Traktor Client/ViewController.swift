//
//  ViewController.swift
//  DiskPlay Traktor Client
//
//  Created by Florian Heller on 16/11/2016.
//  Copyright © 2016 Florian Heller - UHasselt. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

	var midiControl = MidiController()

	var titleLabel:[NSTextField] = []
	
	@IBOutlet weak var titleLabel0: NSTextField!
	@IBOutlet weak var titleLabel1: NSTextField!
	@IBOutlet weak var titleLabel2: NSTextField!
	@IBOutlet weak var titleLabel3: NSTextField!
	@IBOutlet weak var titleLabel4: NSTextField!
	@IBOutlet weak var titleLabel5: NSTextField!
	@IBOutlet weak var titleLabel6: NSTextField!
	@IBOutlet weak var titleLabel7: NSTextField!
	@IBOutlet weak var titleLabel8: NSTextField!
	@IBOutlet weak var titleLabel9: NSTextField!
	@IBOutlet weak var titleLabel10: NSTextField!
	@IBOutlet weak var titleLabel11: NSTextField!
	var MSBs:[UInt8] = [0 ,0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0]
	var LSBs:[UInt8] = [0 ,0, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0]



	override func viewDidLoad() {
		super.viewDidLoad()

		midiControl.viewController = self;
		// Do any additional setup after loading the view.
		titleLabel = [titleLabel0, titleLabel1, titleLabel2, titleLabel3, titleLabel4, titleLabel5, titleLabel6, titleLabel7, titleLabel8, titleLabel9, titleLabel10, titleLabel11]
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	//Update the different label

	func updateByte(msb:Bool, segment:Int, value:UInt8) {
		if (msb==false) {
			LSBs[segment] = value
			DispatchQueue.main.async {
				self.titleLabel[segment].stringValue = "\(Character(UnicodeScalar(((self.MSBs[segment] << 4) | self.LSBs[segment]))))"
				self.MSBs[segment] = 0;
				self.LSBs[segment] = 0;
			}
		}
		else {
			MSBs[segment] = value
		}

		

	}
}



