//
//  Timer.swift
//  App
//
//  Created by Jonas on 06/11/2019.
//

import Foundation

class Timer {
    
    let start: UInt64
    init() {
        start = DispatchTime.now().uptimeNanoseconds
    }
    
    func display(_ label: String){
        let end = DispatchTime.now().uptimeNanoseconds
        
        print("\(label): \(Int((end - start) / 1000000))ms")
    }
}
