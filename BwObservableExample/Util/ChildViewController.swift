//
//  ChildViewController.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2016/06/22.
//  Copyright (c) 2016 Katsuhiko Terada. All rights reserved.
//

import UIKit

// =============================================================================
// MARK: - AnimationType
// =============================================================================

public enum AnimationType
{
    case none
    case alpha
    case layout
    case alpha_layout
    case scale
}

public enum AnimationValue: CGFloat
{
    case hidden = 0.0
    case showed = 1.0
}

open class ChildViewController: CoreViewController , UIGestureRecognizerDelegate
{
    // =============================================================================
    // MARK: - Property
    // =============================================================================
    
    // 親View (ReadOnly)
    public private(set) var parentView: UIView!
    // 移動する場合、位置・サイズの初期値を記憶
    // private var defaultFrame: CGRect = CGRect.zero
    
    // インスタンス生成通知クロージャ(To 呼び出し元）
    private var created: ((_ obj: ChildViewController) -> Void)?
    
    // ------------------
    //var touchEnable: Bool = false
    public var touchTargetView: UIView? {
        didSet
        {
            configureBackgroundTap(touchTargetView: self.touchTargetView)
        }
    }
    
    // ------------------
    // アニメーションの動作時間
    public var duration: TimeInterval = 0.3
    // アニメーションの形式
    public var animationType: AnimationType = .none

    // アニメーション対象View
    public lazy var animationView: UIView = self.view   // animationTypeで動作が決定する
    public var alphaAnimationView: UIView?         // 常にalpha値によりフェードイン・フェードアウトが実行される
    // アニメーションConstraint
    public var animationConstraint: NSLayoutConstraint?
    
    // =============================================================================
    // MARK: - アニメーション
    // =============================================================================
    
    private func animate(value: CGFloat)
    {
        if (self.animationType == .alpha) || (self.animationType == .alpha_layout)
        {
            self.animationView.alpha = value
        }
        else if self.animationType == .scale
        {
            self.animationView.transform = CGAffineTransform(scaleX: value, y: value)
        }
        self.alphaAnimationView?.alpha = value
        self.view.layoutIfNeeded()
    }
    
    /// 表示
    ///
    /// - Parameters:
    ///   - duration: アニメーション期間
    ///   - layout: レイアウトを変更するクロージャ
    ///   - completion: 完了クロージャ
    private func show(withDuration duration: TimeInterval = 0.0, completion:(() -> Void)? = nil)
    {
        if self.animationType == .none { completion?(); return }
        
        let value: CGFloat = AnimationValue.showed.rawValue
        
        //self.layoutIfNeeded()
        self.view.setNeedsUpdateConstraints()
        if (self.animationType == .layout) || (self.animationType == .alpha_layout)
        {
            self.animationConstraint?.constant = 0
        }
        
        if duration > 0
        {
            UIView.animate(withDuration: duration, animations: {
                self.animate(value: value)
            }, completion: { (finished) in
                completion?()
            })
        }
        else
        {
            animate(value: value)
            completion?()
        }
    }
    
    /// 非表示
    ///
    /// - Parameters:
    ///   - duration: アニメーション期間
    ///   - layout: レイアウトを変更するクロージャ
    ///   - completion: 完了クロージャ
    private func hide(withDuration duration: TimeInterval = 0.0, completion:(() -> Void)? = nil)
    {
        if self.animationType == .none { completion?(); return }

        let value: CGFloat = AnimationValue.hidden.rawValue
        
        //self.layoutIfNeeded()
        self.view.setNeedsUpdateConstraints()
        if (self.animationType == .layout) || (self.animationType == .alpha_layout)
        {
            self.animationConstraint?.constant = -((self.animationView.frame.size.width))
        }

        if duration > 0
        {
            UIView.animate(withDuration: duration, animations: {
                self.animate(value: value)
            }, completion: { (finished) in
                completion?()
            })
        }
        else
        {
            animate(value: value)
            completion?()
        }
    }
    
    // =============================================================================
    // MARK: - Background Tap
    // =============================================================================
    
    //    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    //    {
    //        let touch = touches.first!
    //
    //        if let _view = touch.view
    //        {
    //            if  _view == backgroundView
    //            {
    //                dismiss(animation: true)
    //            }
    //        }
    //    }
    
    // バックグラウンドViewをタップすると終了するための設定
    private func configureBackgroundTap(touchTargetView: UIView?)
    {
        if let _touchTargetView = touchTargetView
        {
            _touchTargetView.isUserInteractionEnabled = true
            // これが無いと、自分宛じゃ無いタッチを取得してしまう。
            for view in _touchTargetView.subviews
            {
                view.isUserInteractionEnabled = true
            }
            
            // タップ
            let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            tapGesture.cancelsTouchesInView = true
            tapGesture.delegate = self                              // UIGestureRecognizerDelegateをセット
            _touchTargetView.addGestureRecognizer(tapGesture)        // Viewに追加.
            
            // ロングプレス
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
            longPressGesture.cancelsTouchesInView = true
            longPressGesture.delegate = self                        // UIGestureRecognizerDelegateをセット
            _touchTargetView.addGestureRecognizer(longPressGesture)  // Viewに追加.
        }
    }
    
    // UIGestureRecognizerDelegate
    //
    // Ask the delegate if a gesture recognizer should receive an object representing a touch.
    // UIKit calls this method before calling the touchesBegan(_:with:) method of the gesture recognizer.
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if let _view = touch.view, let _touchTargetView = touchTargetView
        {
            if  _view != _touchTargetView
            {
                return false // 認識しない
            }
        }
        return true
    }
    
    // Tap イベント
    @objc private func tapped(_ sender: UITapGestureRecognizer)
    {
        if sender.state == .ended
        {
            dismiss()
        }
        else if sender.state == .began
        {
            //
        }
    }
    
    // Long Press イベント
    @objc private func longPress(_ sender: UILongPressGestureRecognizer)
    {
        if sender.state == .began
        {
            //
        }
        else if sender.state == .ended
        {
            //
        }
    }
    
    // =============================================================================
    // MARK: - Lifecycle
    // =============================================================================
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override open func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        hide()
    }
    
    override open func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //logger.debug("表示開始 \(self.identifier)")
        // アニメーション実施
        
        show(withDuration: duration) {
            
            //logger.debug("表示完了 \(self.identifier)")
            
            if self.viewDidAappearCounter == 0
            {
                // 最初の実行
                self.created?(self)   // 本インスタンスの呼び出し元に初期化が完了したことを通知する（レイアウトが完了しているタイミング）
                self.created=nil
                
            }
            self.viewDidAppear(withCount: self.viewDidAappearCounter)  // AppearProtocol
            
            self.viewDidAappearCounter += 1
        }
    }
    
    // addChildViewController()で自動呼び出し
    override open func willMove(toParentViewController parent: UIViewController?)
    {
        super.willMove(toParentViewController: parent)
    }
    
    // 手動呼び出し
    override open func didMove(toParentViewController parent: UIViewController?)
    {
        super.didMove(toParentViewController: parent)
    }
    
    // 呼び出し元の参照が無ければインスタンスは消滅する
    private func terminate()
    {
        // Viewを親から解除
        self.view.removeFromSuperview()
        
        if self.parent != nil
        {
            // ViewControllerを親から解除
            self.removeFromParentViewController()
        }
    }
    
    // =============================================================================
    // MARK: - Function
    // =============================================================================
    
    static public var window: UIWindow?
    
    public func show(created: ((_ obj: UIViewController) -> Void)?,
                     completion:((_ obj: UIViewController) -> Void)?
    )
    {
        ChildViewController.window = UIWindow(frame: UIScreen.main.bounds)
        ChildViewController.window?.windowLevel = UIWindowLevelAlert
        ChildViewController.window?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        ChildViewController.window?.rootViewController = self
        ChildViewController.window?.addSubview(self.view)
        ChildViewController.window?.makeKeyAndVisible()
        
        if duration != 0.0
        {
            ChildViewController.window?.alpha = 0.0
            UIView.transition(with: ChildViewController.window!,
                              duration: duration,
                              options: [.transitionCrossDissolve, .curveEaseInOut],
                              animations: { ChildViewController.window?.alpha = 1.0 },
                              completion: { (finished) in
                                created?(self)
            })
        }
    }
    
    /// onで指定したUIViewの上に表示する
    ///
    /// - Parameters:
    ///   - on: Windowを使う
    ///   - created: 生成時クロージャ
    ///   - completion: 終了時クロージャ
    final public func show(on parentView: UIView,
                           created: ((_ obj: ChildViewController) -> Void)?,
                           completion:((_ obj: ChildViewController) -> Void)?)
    {
        self.parentView = parentView
        self.created = created
        self.completion = { vc, animation in
            self.hide(withDuration: self.duration)
            {
                // logger.debug("非表示完了 \(self.identifier)")
                
                completion?(vc as! ChildViewController)
                self.terminate()    // ChildViewController終了処理
            }
        }
        
        //self.view.autoFit()  // <--- autoresizingMaskを有効にする
        self.parentView.addSubview(self.view)
        self.parentView.addConstraint(toChildView: self.view)  // <--- Constraintを設定する
    }
    
    /// withParentViewControllerで指定したUIViewControllerの上に表示する
    ///
    /// - Parameters:
    ///   - pvc: 親UIViewController
    ///   - parentView: 親UIView
    ///   - created: 生成時クロージャ
    ///   - completion: 終了時クロージャ
    final public func show(with pvc: UIViewController,
                           on parentView: UIView,
                           created: ((_ obj: ChildViewController) -> Void)?,
                           completion:((_ obj: ChildViewController) -> Void)?)
    {
        self.parentView = parentView
        self.created = created
        self.completion = { vc, animation in
            self.hide(withDuration: self.duration)
            {
                // logger.debug("非表示完了 \(self.identifier)")
                
                completion?(vc as! ChildViewController)
                self.terminate()    // ChildViewController終了処理
            }
        }
        
        self.view.frame = self.parentView.bounds
        
        pvc.addChildViewController(self)
        
        //self.view.autoFit()  // <--- autoresizingMaskを有効にする
        self.parentView.addSubview(self.view)
        self.parentView.addConstraint(toChildView: self.view)  // <--- Constraintを設定する
    }
    
    // =============================================================================
    // MARK: - AppearProtocol
    // =============================================================================

    open func viewDidAppear(withCount count: Int){}
}

// =============================================================================
// MARK: - UIView:addConstraint
// =============================================================================

extension UIView {
    
    public func addConstraint(toChildView childView:UIView)
    {
        childView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraints([NSLayoutConstraint(item: childView, attribute:.top, relatedBy:.equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
                             NSLayoutConstraint(item: childView, attribute:.bottom, relatedBy:.equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0),
                             NSLayoutConstraint(item: childView, attribute:.left, relatedBy:.equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
                             NSLayoutConstraint(item: childView, attribute:.right, relatedBy:.equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)])
    }
    
    
}

extension UIView
{
    // =============================================================================
    // MARK: - UIViewの外景
    // =============================================================================
    
    // UIViewの外景をレクトアングルにするための半径を指定する
    @IBInspectable
    public var cornerRadius: CGFloat
    {
        set
        {
            self.layer.cornerRadius = newValue
            if self is UILabel
            {
                let label = self as! UILabel
                label.clipsToBounds = true
            }
            self.setNeedsLayout()
        }
        get
        {
            return self.layer.cornerRadius
        }
    }
    
    // UIViewの外枠の線を描画する（幅）
    @IBInspectable
    public var borderWidth: CGFloat
    {
        set
        {
            self.layer.borderWidth = newValue
            self.setNeedsLayout()
        }
        get
        {
            return self.layer.borderWidth
        }
    }
    
    // UIViewの外枠の線を描画する（色）
    @IBInspectable
    public var borderColor: UIColor
    {
        set
        {
            self.layer.borderColor = newValue.cgColor
            self.setNeedsLayout()
        }
        get
        {
            if let _borderColor = self.layer.borderColor
            {
                return UIColor(cgColor: _borderColor)
            }
            return UIColor.clear
        }
    }
}

// =============================================================================
// MARK: - ViewControllerGettable
// =============================================================================

public protocol ViewControllerGettable where Self: UIViewController
{
    static var storyboardName: String { get }
    static func getInstance() -> Self
}

extension ViewControllerGettable
{
    public static func getInstance() -> Self
    {
        let storyboardInstance = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboardInstance.instantiateViewController(withIdentifier: String(describing: self)) as! Self
        return vc
    }
}
