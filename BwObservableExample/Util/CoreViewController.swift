//
//  CoreViewController.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2017/10/17.
//  Copyright (c) 2017 Katsuhiko Terada. All rights reserved.
//

import UIKit

public protocol Dismissable: class {
    func dismiss()
    func dismiss(animation: Bool)
}

// 主にViewController遷移に関する機能を実装
open class CoreViewController: UIViewController, Dismissable {
    private var onceDismissed: Bool = false    // 一度だけ終了時に実行する
    //private var onceLayouted: Bool = false     // 一度だけレイアウト時に実行する
    public private(set) var viewDidLoaded: Bool = false

    // =============================================================================
    // MARK: - プロパティ
    // =============================================================================

    /// 表示カウンター
    public var viewDidAappearCounter: Int = 0          // 自動でインクリメントしないのでサブクラスでインクリさせてください
    public var viewDidLayoutSubviewsCounter: Int = 0
    /// 完了時指定がない場合のアニメーション有無
    public var animateBeforeCompleted: Bool = false

    /// viewDidLoad()内で実行
    public var execAfterViewDidLoad: ((_ obj: CoreViewController) -> Void)? {
        didSet {
            if viewDidLoaded {
                execAfterViewDidLoad?(self)
                execAfterViewDidLoad = nil
            }
        }
    }

    @available(*, deprecated, message: "互換性のため残しているが、廃止予定")
    public var viewDidLoadedCompletion: ((_ obj: CoreViewController) -> Void)? {
        didSet {
            execAfterViewDidLoad = viewDidLoadedCompletion
        }
    }

    /// 完了クロージャ
    public var completion: ((_ obj: CoreViewController, _ animation: Bool) -> Void)?

    // =============================================================================
    // MARK: - API
    // =============================================================================

    /// 表示を終了する
    ///
    /// - Parameters:
    ///   - result: 結果値
    ///   - animation: 終了のアニメーションの有無
    final public func dismiss(animation: Bool) {
        guard !onceDismissed else { return }
        onceDismissed = true
        completion?(self, animation)       // 終了時のクロージャを呼び出す
        completion = nil
        dismissed()                         // 子クラス（オーバーライドしていれば）に通知する
    }

    final public func dismiss() {
        dismiss(animation: animateBeforeCompleted)
    }

    // =============================================================================
    // MARK: - LifeCycle
    // =============================================================================

    deinit {
        // ナビゲーションバーの戻るボタン "<" で画面を終了する場合
        // ナビゲーションバーの戻るボタン "<" がある場合は、self.resultをセットしておくこと。
        dismiss()
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialized()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialized()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        execAfterViewDidLoad?(self)
        execAfterViewDidLoad = nil
        viewDidLoaded = true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onceDismissed = false // インスタンスを残してまたshowした場合にリセットする必要がある
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewDidLayoutSubviews(withCount: viewDidLayoutSubviewsCounter)
        viewDidLayoutSubviewsCounter += 1
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidLayoutSubviewsCounter = 0
    }

    // =============================================================================
    // MARK: - 子クラスでオーバーライドして使用します
    // =============================================================================

    // 初期化時に呼び出される
    open func initialized() {}

    // レイアウト完了後に一度だけ呼び出される
    open func viewDidLayoutSubviews(withCount count: Int) {}

    // 終了時に呼び出される（保持しているインスタンスなどの解放）
    open func dismissed() {}
}

extension CoreViewController {
    // ナビゲーション表示をする
    open func push(with navigation: UINavigationController?, animated: Bool = true, completion: ((_ obj: CoreViewController, _ animation: Bool) -> Void)?) {
        self.animateBeforeCompleted = animated

        // 終了クロージャの設定
        self.completion = { viewController/*, result*/, _animated in

            // ### ATTN ### DispatchQueue.main.async()などで遅延実行させないこと!!!

            completion?(viewController/*, result*/, _animated)
            // 画面終了（インスタンスの消滅）
            viewController.navigationController?.popViewController(animated: _animated)
        }
        // 画面表示
        navigation?.pushViewController(self, animated: animated)
    }

    // モーダル表示をする ### ATTN ### ナビゲーションがない場合
    open func present(on parent: UIViewController, animated: Bool = true, completion: ((_ obj: CoreViewController, _ animation: Bool) -> Void)?) {
        self.animateBeforeCompleted = animated

        // 終了クロージャの設定
        self.completion = { viewController/*, result*/, _animated in

            // ### ATTN ### DispatchQueue.main.async()などで遅延実行させないこと!!!

            completion?(viewController/*, result*/, _animated)
            // 画面終了（インスタンスの消滅）
            viewController.dismiss(animated: _animated, completion: nil)
        }
        // 画面表示
        parent.present(self, animated: animated)
    }

    // モーダル表示をする ### ATTN ### ナビゲーションがある場合
    open func present(navigationController: UINavigationController, on parent: UIViewController, animated: Bool = true, completion: ((_ obj: CoreViewController, _ animation: Bool) -> Void)?) {
        self.animateBeforeCompleted = animated

        self.completion = { vc, _animated in

            // ### ATTN ### DispatchQueue.main.async()などで遅延実行させないこと!!!

            completion?(vc, _animated)
            vc.dismiss(animated: _animated, completion: nil)
        }
        parent.present(navigationController, animated: animated)
    }
}
