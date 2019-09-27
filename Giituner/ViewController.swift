//
//  ViewController.swift
//  Giituner
//
//  Created by Abdallah on 2019-09-25.
//  Copyright © 2019 Abdallah Karam. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController {
    
    // UI elements
    
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var estimatedFrequencyLabel: UILabel!
    
    // View elements
    
    var estimated = "Estimating..."
    var note = "Loading..."
    var mic = AKMicrophone()
    var tracker = AKFrequencyTracker()
    var silence = AKBooster()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Setting up AudioKit
        
        AKSettings.audioInputEnabled = true
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        AudioKit.output = silence
        
        do {
            try AudioKit.start()
        }
        
        catch {
            print("Failed to start AudioKit.")
        }
        
        mic?.start()
        tracker.start()
        
        // Main work is called here, changing the numbers in the if loop will affect the sounds that are being tracked.
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.tracker.frequency > 0 && self.tracker.frequency < 2000 && self.tracker.amplitude > 0.1 {
                self.onFrequencyChange(frequency: self.tracker.frequency)
            }
        }
        
    }
    
    // Used to find closest note in sorted array.
    
    func binarySearch(_ arr: Array<Double>, value: Double) -> Int {
        if value < arr[0] {
            return 0
        }
        
        if value > arr[arr.count - 1] {
            return arr.count - 1
        }
        
        var lower = 0
        var upper = arr.count - 1
        
        while lower <= upper {
            let curr = (lower + upper) / 2
    
            if arr[curr] == value {
                return curr
            }

            else {
                if arr[curr] > value {
                    upper = curr - 1
                }
                
                else if arr[curr] < value {
                    lower = curr + 1
                }
            }
        }
        
        return (arr[lower] - value) < (value - arr[upper]) ? lower : upper
    }
    
    // Main work is done here
    
    func onFrequencyChange(frequency: Double) {
        
        let workItem = DispatchWorkItem {
            let octave = Double(self.calculateOctave(fq: frequency))
            let search = frequency * Double(pow(0.5, octave))
            let found = self.binarySearch(Notes.frequencies, value: search)
            self.note = Notes.namesUsingSharps[found]
            self.estimated = String(format: "%.1f", Notes.frequencies[found] * pow(2, octave))
            
            DispatchQueue.main.async{
                // updating UI here
                self.pitchLabel.text = String(format:"%.1f", frequency) + "Hz"
                self.noteLabel.text = self.note + String(format: "%.0f", octave)
                self.estimatedFrequencyLabel.text = "Tune to: " + self.estimated + "Hz"
            }
        }
        
        DispatchQueue.global().async(execute: workItem)
            
        DispatchQueue.main.async{
            // If work doesn't get finished in time, cancel it so no new threads are created
            workItem.cancel()
        }
    }
    
    // Calculate the octave of the incoming frequency
    
    func calculateOctave(fq: Double) -> Int {
        var note = fq
        var octave = 0
        let lower = Notes.frequencies[0]
        let upper = Notes.frequencies[11]
        while note >= lower && !(note <= upper) {
            note = note / 2
            octave += 1
        }
        
        return octave
    }



}

