//
//  ScrollableViewController.swift
//  ScrollableCardView
//
//  Created by 劉峻岫 on 2020/7/23.
//  Copyright © 2020 addcn. All rights reserved.
//

import UIKit
import SnapKit

private enum State {
    case closed
    case open
}

extension State {
    var opposite: State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}

// MARK:
/// CardViewController 本身是有卡片效果的 container，可以吃任何類型的 content。
///
/// - Note:
/// 當 popupOffset  >  0  時，卡片收起來後會顯示在畫面上，popupOffset 越大，卡片在畫面上顯示的越多

class ScrollableViewController: UIViewController {
    private lazy var popView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        return view
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()

    private lazy var rightBarButton: UIButton = {
        let button = UIButton {
            $0.setImage(#imageLiteral(resourceName: "back_i_os_gray"), for: .normal)
            $0.addTarget(self, action: #selector(popupViewTapped), for: .touchUpInside)
            $0.tintColor = .black
        }
        return button
    }()

    @objc private func popupViewTapped(sender: UIButton) {
        animateTransitionIfNeeded(to: currentState.opposite, duration: 0.5)
    }

    lazy var titileLineView: UIView = {
        let view = UIView {
            $0.backgroundColor = .black
        }
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel {
            $0.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            $0.textAlignment = .center
        }
        return label
    }()

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    // MARK: - Other Properties
    private let popViewHeight: CGFloat
    private let popupOffset: CGFloat
    private let childViewController: UIViewController

    // MARK: - 開啟可以拉的效果
    var canDrag = false {
        didSet {
            if canDrag { popView.addGestureRecognizer(panRecognizer) }
        }
    }

    private var animationProgress: CGFloat = 0
    private var currentState: State = .closed

    /// popView 的高度為自定義
    ///
    /// - Parameters:
    ///   - popViewHeight: 彈出卡片的高度
    ///   - popupOffset: 卡片收起來後顯示在畫面的高度
    ///   - childViewController: 實際的 VC
    ///
    init(popViewHeight: CGFloat, popupOffset: CGFloat, childViewController: UIViewController) {
        self.popViewHeight = popViewHeight
        self.popupOffset = popViewHeight - popupOffset
        self.childViewController = childViewController
        super.init(nibName: String(describing: ScrollableViewController.self), bundle: nil)
    }

    /// popView 的高度根據 childVC 的內容高度做自動調整
    ///
    /// - Parameters:
    ///   - containerHeight: childVC 的高度
    ///   - popupOffset: 卡片收起來後顯示在畫面的高度
    ///   - childViewController: 實際的 VC
    ///
    init(containerHeight: CGFloat, popupOffset: CGFloat, childViewController: UIViewController) {
        popViewHeight = containerHeight + 61
        self.popupOffset = popViewHeight - popupOffset
        self.childViewController = childViewController
        super.init(nibName: String(describing: ScrollableViewController.self), bundle: nil)
    }

    /// popView 的高度根據 ScrollVIew 的內容高度做自動調整
    ///  例：根據 tableview content size 調整
    ///
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - popupOffset: 卡片收起來後顯示在畫面的高度
    ///   - childViewController: 實際的 VC

    init(scrollView: UIScrollView, popupOffset: CGFloat, childViewController: UIViewController) {
        childViewController.loadViewIfNeeded()
        scrollView.layoutIfNeeded()
        popViewHeight = scrollView.contentSize.height + 61

        self.popupOffset = popViewHeight - popupOffset
        self.childViewController = childViewController
        super.init(nibName: String(describing: ScrollableViewController.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        childViewController.view.frame = containerView.bounds
        addChild(childViewController)
        containerView.addSubview(childViewController.view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateTransitionIfNeeded(to: .open, duration: 1.0)
    }

    private var bottomConstraint = NSLayoutConstraint()
    private var transitionAnimator = UIViewPropertyAnimator()

    private func setupUI() {
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }

        view.addSubview(popView)
        popView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(popViewHeight)
        }
        bottomConstraint = popView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: popupOffset
        )
        bottomConstraint.isActive = true

        // MARK: - Title
        popView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
        }

        popView.addSubview(rightBarButton)
        rightBarButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(24)
        }

        popView.addSubview(titileLineView)
        titileLineView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
        }

        popView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titileLineView.snp.bottom)
        }
    }

    // MARK: - Pan Action
    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(popupViewPanned))
        return recognizer
    }()

    @objc private func popupViewPanned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            animateTransitionIfNeeded(to: currentState.opposite, duration: 0.5)
            transitionAnimator.pauseAnimation()
            animationProgress = transitionAnimator.fractionComplete

        case .changed:
            let translation = recognizer.translation(in: popView)
            var fraction = -translation.y / popupOffset
            if currentState == .open { fraction *= -1 }
            if transitionAnimator.isReversed { fraction *= -1 }
            transitionAnimator.fractionComplete = fraction + animationProgress

        case .ended:
            let yVelocity = recognizer.velocity(in: popView).y
            let shouldClose = yVelocity > 0
            if yVelocity == 0 {
                transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            switch currentState {
            case .open:
                if !shouldClose, !transitionAnimator.isReversed {
                    transitionAnimator.isReversed = !transitionAnimator.isReversed
                }
                if shouldClose, transitionAnimator.isReversed {
                    transitionAnimator.isReversed = !transitionAnimator.isReversed
                }

            case .closed:
                if shouldClose, !transitionAnimator.isReversed {
                    transitionAnimator.isReversed = !transitionAnimator.isReversed
                }
                if !shouldClose, transitionAnimator.isReversed {
                    transitionAnimator.isReversed = !transitionAnimator.isReversed
                }
            }
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)

        default:
            break
        }
    }

    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        if transitionAnimator.isRunning { return }
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1, animations: {
            switch state {
            case .open:
                self.bottomConstraint.constant = 0
                self.popView.layer.cornerRadius = 10
                self.overlayView.alpha = 0.7

            case .closed:
                self.bottomConstraint.constant = self.popupOffset
                self.popView.layer.cornerRadius = 0
                self.overlayView.alpha = 0
            }
            self.view.layoutIfNeeded()
        })
        transitionAnimator.addCompletion { position in
            switch position {
            case .start:
                self.currentState = state.opposite

            case .end:
                self.currentState = state

            case .current:
                ()

            default:
                break
            }
            switch self.currentState {
            case .open:
                self.bottomConstraint.constant = 0

            case .closed:
                self.bottomConstraint.constant = self.popupOffset

                // 假如 popView 縮下去後沒在畫面上，就直接 dismiss
                if self.popView.frame.minY > UIScreen.main.bounds.size.height - 20 {
                    self.dismiss(animated: false, completion: nil)
                }
            }
        }
        transitionAnimator.startAnimation()
    }
}

