//
//  FirstViewController.swift
//  BwObservableExample
//
//  Created by Katsuhiko Terada on 2018/07/31.
//  Copyright © 2018年 Katsuhiko Terada. All rights reserved.
//

import UIKit

class FirstViewController: ChildViewController, ViewControllerGettable {
    static var storyboardName: String = "Main"

    @IBOutlet weak var label: UILabel!

    /// このインスタンスが消滅すると自動的にsubscribeを停止します
    var disaposeBag = BwDisposeBag()
    lazy var vm = { DummyViewModel() }()

    deinit {
        print("FirstViewController:deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /// subscribeする前にイベントを発生させる
        vm.firstButton()
        /// 何度でも実行＆subscribe以前の最新のイベントを取得する
        vm.ex.firstButton.once(self, latest: true) { [weak self] (counter) in
            self?.label.text = String(counter)
        }
    }

    @IBAction func close(_ sender: Any) {
        dismiss()
    }

    @IBAction func pushed(_ sender: Any) {
        vm.firstButton()
    }
}
