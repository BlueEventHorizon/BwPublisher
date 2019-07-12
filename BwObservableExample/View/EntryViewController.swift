//
//  EntryViewController.swift
//  BwObservableExample
//
//  Created by 寺田 克彦 on 2018/08/24.
//  Copyright © 2018年 beowulf-tech. All rights reserved.
//

import UIKit

class EntryViewController: UIViewController {
    @IBOutlet weak var baseView: UIView!

    let task1: BwObservable<Int> = BwObservable<Int>()
    let task2: BwObservable<Int> = BwObservable<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()

        task1.subscribe(self) { _ in
            let vc = FirstViewController.getInstance()
            vc.show(with: self, on: self.baseView, created: nil, completion: { (_) in
                self.task2.publish(1)
            })
        }

        task2.subscribe(self) { _ in
            let vc = SecondViewController.getInstance()
            vc.show(with: self, on: self.baseView, created: nil, completion: { (_) in
                self.task1.publish(1)
            })
        }

        self.task1.publish(1)
    }
}
