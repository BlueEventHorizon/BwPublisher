//
//  SecondViewController.swift
//  BwObservableExample
//
//  Created by Katsuhiko Terada on 2018/07/31.
//  Copyright © 2018年 Katsuhiko Terada. All rights reserved.
//

import UIKit

class SecondViewController: ChildViewController, ViewControllerGettable
{
    static var storyboardName: String = "Main"
    
    @IBOutlet weak var label: UILabel!
    
    /// このインスタンスが消滅すると自動的にsubscribeを停止します
    var disaposeBag = BwDisposeBag()
    lazy var vm = {DummyViewModel()}()
    
    deinit {
        print("SecondViewController:deinit")
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        /// subscribeする前にイベントを発生させる
        vm.secondButton()
        /// 一度だけ実行＆subscribe以降のイベントを取得する
        vm.ex.secondButton.subscribe(self, once: true, latest: false) { [weak self] (counter) in
            self?.label.text = String(counter)
        }?.disposed(by: disaposeBag)
    }

    @IBAction func close(_ sender: Any)
    {
        dismiss()
    }
    
    @IBAction func pushed(_ sender: Any)
    {
        vm.secondButton()
    }
}

