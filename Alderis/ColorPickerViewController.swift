//
//  ColorPickerViewController.swift
//  Alderis
//
//  Created by Adam Demasi on 12/3/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

import UIKit

/// Provides the Color Picker user interface.
///
/// Present this view controller to display the color picker. Do not push it onto a navigation controller stack. In horizontally and vertically regular size class environments, for instance on iPad and Mac, the picker will be presented as a popover. This means that you must set  before presentation.
///
/// To review examples of ColorPickerViewController in use, run `pod try Alderis`.
@objc(HBColorPickerViewController)
open class ColorPickerViewController: UIViewController {

	/// Do not rely on this fallback value - always specify a color!
	private static let defaultColor = UIColor(white: 0.6, alpha: 1)

	/// Initialise an instance of ColorPickerViewController with a configuration object.
	///
	/// Remember to set the `delegate` before presenting the view controller.
	public init(configuration: ColorPickerConfiguration) {
		self.configuration = configuration
		super.init(nibName: nil, bundle: nil)
		setUp()
	}

	/// The delegate that will receive the user’s selection upon tapping the Done button, or a cancellation upon tapping the Cancel button.
	@objc open weak var delegate: ColorPickerDelegate? {
		didSet {
			innerViewController?.delegate = delegate
		}
	}

	/// The configuration of the color picker. Use this to set the initially selected color, as well as other behavioral options.
	///
	/// Making changes to this value or its properties after the color picker interface has been presented may result in undefined behavior.
	///
	/// - see: `ColorPickerConfiguration`
	@objc open var configuration: ColorPickerConfiguration!

	/// Deprecated. Set overrideSmartInvert on the `ColorPickerConfiguration` instead.
	///
	/// - see: `ColorPickerConfiguration.overrideSmartInvert`
	@available(*, deprecated, message: "Use ColorPickerConfiguration instead")
	@objc open var overrideSmartInvert = true

	/// Deprecated. Set color on the `ColorPickerConfiguration` instead.
	///
	/// - see: `ColorPickerConfiguration.color`
	@available(*, deprecated, message: "Use ColorPickerConfiguration instead")
	@objc open var color = ColorPickerViewController.defaultColor

	// A width divisible by 12 (the number of items wide in the swatch).
	private var finalWidth: CGFloat {
		if modalPresentationStyle == .popover {
			return 336
		} else {
			return floor(min(384, view.frame.size.width - 30) / 12) * 12
		}
	}

	private var isFullScreen: Bool {
		return modalPresentationStyle != .popover
	}

	private var innerViewController: ColorPickerInnerViewController!

	private var backdropView: UIView!
	private var backgroundView: UIVisualEffectView!

	private var widthLayoutConstraint: NSLayoutConstraint!
	private var bottomLayoutConstraint: NSLayoutConstraint!
	private var bottomAnimatingLayoutConstraint: NSLayoutConstraint!

	private var _transitioningDelegate = BottomSheetTransitioningDelegate()
	private var initialBottomSafeAreaInset: CGFloat?
	private var isKeyboardVisible = false

	/// :nodoc:
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		self.configuration = nil
		super.init(nibName: nil, bundle: nil)
		setUp()
	}

	/// :nodoc:
	required public init?(coder: NSCoder) {
		self.configuration = nil
		super.init(coder: coder)
		setUp()
	}

	private func setUp() {
		if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
			modalPresentationStyle = .popover
		} else {
			modalPresentationStyle = .overCurrentContext
		}

		transitioningDelegate = _transitioningDelegate
	}

	/// :nodoc:
	override open func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.isNavigationBarHidden = true
		view.backgroundColor = .clear

		if isFullScreen {
			backdropView = UIView()
			backdropView.translatesAutoresizingMaskIntoConstraints = false
			backdropView.backgroundColor = Assets.backdropColor
			backdropView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissGestureFired(_:))))
			view.addSubview(backdropView)
		}

		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)

		if isFullScreen {
			backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
			backgroundView.translatesAutoresizingMaskIntoConstraints = false
			backgroundView.clipsToBounds = true
			backgroundView.layer.cornerRadius = 13
			if #available(iOS 13, *) {
				backgroundView.layer.cornerCurve = .continuous
			}
			containerView.addSubview(backgroundView)
		}

		if configuration == nil {
			// Yes, Swift, I know my code for handling deprecated API usage uses deprecated API 🙄
			configuration = ColorPickerConfiguration(color: color)
			configuration.overrideSmartInvert = overrideSmartInvert
		}

		innerViewController = ColorPickerInnerViewController(delegate: delegate, configuration: configuration)
		innerViewController.willMove(toParent: self)
		addChild(innerViewController)
		innerViewController.view.translatesAutoresizingMaskIntoConstraints = false
		innerViewController.view.clipsToBounds = true
		innerViewController.view.layer.cornerRadius = 13
		if isFullScreen {
			innerViewController.view.layer.borderWidth = 1
			innerViewController.view.layer.borderColor = Assets.borderColor.cgColor
		}
		if #available(iOS 13, *) {
			innerViewController.view.layer.cornerCurve = .continuous
		}
		containerView.addSubview(innerViewController.view)

		widthLayoutConstraint = containerView.widthAnchor.constraint(equalToConstant: finalWidth)
		bottomLayoutConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
		bottomAnimatingLayoutConstraint = view.bottomAnchor.constraint(equalTo: containerView.topAnchor)

		if isFullScreen {
			NSLayoutConstraint.activate([
				backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
				backdropView.topAnchor.constraint(equalTo: view.topAnchor),
				backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

				backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
				backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
				backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
				backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

				containerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
				bottomLayoutConstraint
			])
		} else {
			NSLayoutConstraint.activate([
				containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
				containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
			])
		}

		NSLayoutConstraint.activate([
			widthLayoutConstraint,

			innerViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			innerViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			innerViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
			innerViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		])
	}

	/// :nodoc:
	override open func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		widthLayoutConstraint.constant = finalWidth
	}

	/// :nodoc:
	override open func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()

		if !isKeyboardVisible {
			initialBottomSafeAreaInset = view.safeAreaInsets.bottom
			bottomLayoutConstraint.constant = initialBottomSafeAreaInset == 0 ? 15 : 0
		}
	}

	/// :nodoc:
	open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		super.preferredContentSizeDidChange(forChildContentContainer: container)

		if !isFullScreen {
			preferredContentSize = CGSize(width: finalWidth,
																		height: innerViewController.preferredContentSize.height)
		}
	}

	/// :nodoc:
	override open func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if navigationController != nil && navigationController!.viewControllers.count > 1 {
			assertionFailure("Do not push \(String(describing: type(of: self))) onto a navigation controller stack. It must be presented using UIViewController.present(_:animated:completion:).")
		}

		if animated && isFullScreen {
			backdropView.alpha = 0
			bottomLayoutConstraint.isActive = false
			bottomAnimatingLayoutConstraint.isActive = true
			view.layoutIfNeeded()

			UIView.animate(withDuration: 0.4,
										 delay: 0,
										 usingSpringWithDamping: 2,
										 initialSpringVelocity: 0.5,
										 options: [],
										 animations: {
											self.backdropView.alpha = 1
											self.bottomLayoutConstraint.isActive = true
											self.bottomAnimatingLayoutConstraint.isActive = false
											self.view.layoutIfNeeded()
										 },
										 completion: nil)
		}
	}

	private let keyboardNotificationNames = [
		UIResponder.keyboardWillShowNotification,
		UIResponder.keyboardWillHideNotification,
		UIResponder.keyboardWillChangeFrameNotification
	]

	/// :nodoc:
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		keyboardNotificationNames.forEach {
			NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: $0, object: nil)
		}
	}

	/// :nodoc:
	override open func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		keyboardNotificationNames.forEach {
			NotificationCenter.default.removeObserver(self, name: $0, object: nil)
		}

		if animated && isFullScreen {
			backdropView.alpha = 1
			bottomLayoutConstraint.isActive = true
			bottomAnimatingLayoutConstraint.isActive = false
			view.layoutIfNeeded()

			UIView.animate(withDuration: 0.4,
										 delay: 0,
										 usingSpringWithDamping: 0.8,
										 initialSpringVelocity: 0.5,
										 options: [],
										 animations: {
											self.backdropView.alpha = 0
											self.bottomLayoutConstraint.isActive = false
											self.bottomAnimatingLayoutConstraint.isActive = true
											self.view.layoutIfNeeded()
										 },
										 completion: nil)
		}
	}

	/// :nodoc:
	override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if isFullScreen {
			// CGColor doesn’t support dynamic colors, so we need to set this again.
			innerViewController.view.layer.borderColor = Assets.borderColor.cgColor
		}
	}

	@objc private func keyboardFrameWillChange(_ notification: Notification) {
		if !isFullScreen {
			return
		}

		guard let userInfo = notification.userInfo,
			let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
			let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
			let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
			else {
				return
		}

		isKeyboardVisible = notification.name != UIResponder.keyboardWillHideNotification

		var options: UIView.AnimationOptions = .beginFromCurrentState
		options.insert(.init(rawValue: curve << 16))

		UIView.animate(withDuration: duration,
									 delay: 0,
									 options: options,
									 animations: {
										let bottom = max((self.isKeyboardVisible ? keyboardEndFrame.size.height : 0) - (self.initialBottomSafeAreaInset ?? 0), 0) + (self.isKeyboardVisible && self.initialBottomSafeAreaInset != 0 ? 15 : 0)
										self.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
										self.view.layoutIfNeeded()
									 })
	}

	@objc private func dismissGestureFired(_ gestureRecognizer: UITapGestureRecognizer) {
		if gestureRecognizer.state == .ended {
			if isKeyboardVisible {
				view.endEditing(true)
			} else {
				delegate?.colorPickerDidCancel?(self)
				dismiss(animated: true, completion: nil)
			}
		}
	}

}
