//
//  DummyViewModel.swift
//  BwObservableExample
//
//  Created by Katsuhiko Terada on 2018/08/02.
//  Copyright © 2018年 Katsuhiko Terada. All rights reserved.
//

import Foundation

class DummyViewModel
{
    class Ex
    {
        var firstButton: BwObservable<Int> = BwObservable<Int>()
        var secondButton: BwObservable<Int> = BwObservable<Int>()
    }
    let ex = Ex()
    
    private var firstCounter: Int = 0
    func firstButton()
    {
        firstCounter += 1
        ex.firstButton.publish(firstCounter)
    }
    
    private var secondCounter: Int = 0
    func secondButton()
    {
        secondCounter += 1
        ex.secondButton.publish(secondCounter)
    }
}
