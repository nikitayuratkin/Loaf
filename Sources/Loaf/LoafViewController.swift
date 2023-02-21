//
//  LoafViewController.swift
//  Loaf
//
//  Created by iOS Dev on 21.02.2023.
//  Copyright © 2023 Mat Schmid. All rights reserved.
//

import UIKit

final class LoafViewController: UIViewController {
    var loaf: Loaf
    var isCancelButtonNeeded: Bool = false
    
    let cancelXButton = UIButton()
    let label = UILabel()
    let imageView = UIImageView(image: nil)
    var font = UIFont.systemFont(ofSize: 14, weight: .medium)
    var textAlignment: NSTextAlignment = .left
    var transDelegate: UIViewControllerTransitioningDelegate
    weak var delegate: LoafDelegate?
    
    init(_ toast: Loaf) {
        self.loaf = toast
        self.transDelegate = Manager(loaf: toast, size: .zero)
        super.init(nibName: nil, bundle: nil)
        
        var width: CGFloat?
        if case let Loaf.State.custom(style) = loaf.state {
            self.font = style.font
            self.textAlignment = style.textAlignment
            
            switch style.width {
            case .fixed(let value):
                width = value
            case .screenPercentage(let percentage):
                guard 0...1 ~= percentage else { return }
                width = UIScreen.main.bounds.width * percentage
            }
        }
        
        let height = max(toast.message.heightWithConstrainedWidth(width: 240, font: font) + 12, 40)
        preferredContentSize = CGSize(width: width ?? 280, height: height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelXButton.setImage(Images.cancelIcon, for: .normal)
        cancelXButton.alpha = 0
        cancelXButton.isUserInteractionEnabled = false
        cancelXButton.contentVerticalAlignment = .fill
        cancelXButton.contentHorizontalAlignment = .fill
        cancelXButton.translatesAutoresizingMaskIntoConstraints = false
        
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.font = font
        label.textAlignment = textAlignment
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if loaf.dismissalReason == .interactive {
            let string = loaf.message
            let range               = (string as NSString).range(of: "Настройки")
            let attributedString    = NSMutableAttributedString(string: string)
            
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber(value: 1), range: range)
            label.attributedText = attributedString
        } else {
            label.text = loaf.message
        }
        
        switch loaf.dismissalReason {
        case .all:
            isCancelButtonNeeded = false
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
            swipeGesture.direction = .up
            view.addGestureRecognizer(swipeGesture)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
            view.addGestureRecognizer(tapGesture)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + loaf.duration.length, execute: {
                self.dismiss(animated: true) { [weak self] in
                    self?.delegate?.loafDidDismiss()
                    self?.loaf.completionHandler?(.all)
                }
            })
        case .interactive:
            isCancelButtonNeeded = true
            let buttonTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCancelButtonTap))
            cancelXButton.addGestureRecognizer(buttonTapGesture)
            let tapViewGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapInteractiveGesture))
            view.addGestureRecognizer(tapViewGesture)
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeInteractiveGesture))
            swipeGesture.direction = .up
            view.addGestureRecognizer(swipeGesture)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + loaf.duration.length, execute: {
                self.dismiss(animated: true) { [weak self] in
                    self?.delegate?.loafDidDismiss()
                }
            })
        }
        
        switch loaf.state {
        case .success:
            imageView.image = Loaf.Icon.success
            view.backgroundColor = UIColor(hexString: "#8e8e8e")
            constrainWithIconAlignment(.left)
        case .warning:
            imageView.image = Loaf.Icon.warning
            view.backgroundColor = UIColor(hexString: "#8e8e8e")
            constrainWithIconAlignment(.left)
        case .error:
            imageView.image = Loaf.Icon.error
            view.backgroundColor = UIColor(hexString: "#8e8e8e")
            constrainWithIconAlignment(.left)
        case .info:
            imageView.image = Loaf.Icon.info
            view.backgroundColor = UIColor(hexString: "#8e8e8e")
            constrainWithIconAlignment(.left)
        case .withCancelButton:
            imageView.image = Loaf.Icon.closeIcon
            view.backgroundColor = UIColor(hexString: "#8e8e8e")
            constrainWithIconAlignment(.right)
        case .custom(style: let style):
            imageView.image = style.icon
            view.backgroundColor = style.backgroundColor
            imageView.tintColor = style.tintColor
            label.textColor = style.textColor
            label.font = style.font
            constrainWithIconAlignment(style.iconAlignment, showsIcon: imageView.image != nil)
            
        }
        
    }
    
    // MARK: - Handlers Methods
    /// For DismissalReason: .all
    @objc private func handleTapGesture() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
            self?.loaf.completionHandler?(.all)
        }
    }
    
    @objc private func handleSwipeGesture() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
            self?.loaf.completionHandler?(.all)
        }
    }
    
    /// For DismissalReason: .interactive
    @objc private func handleCancelButtonTap() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
        }
    }
    
    @objc private func handleTapInteractiveGesture() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
            self?.loaf.completionHandler?(.interactive)
        }
    }
    
    @objc private func handleSwipeInteractiveGesture() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
        }
    }
    
    // MARK: - Setup constraints depending on the alignment
    private func constrainWithIconAlignment(_ alignment: Loaf.Style.IconAlignment, showsIcon: Bool = true) {
        view.addSubview(cancelXButton)
        view.addSubview(label)
        
        if showsIcon {
            view.addSubview(imageView)
            setButtonConstraints()
            switch alignment {
            case .left:
                setButtonConstraintsWithLeftImage()
            case .right:
                setButtonConstraintsWithRightImage()
            }
        } else {
            setButtonConstraintsWithoutImage()
        }
    }
    
    // MARK: - Setup cancelXButton constraints
    
    private func setButtonConstraints() {
        NSLayoutConstraint.activate([
            cancelXButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            cancelXButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cancelXButton.heightAnchor.constraint(equalToConstant: 40),
            cancelXButton.widthAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    private func setButtonConstraintsWithLeftImage () {
        if isCancelButtonNeeded {
            isButtonNeeded(true)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                
                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: cancelXButton.trailingAnchor, constant: -4),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            isButtonNeeded(false)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                
                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: cancelXButton.trailingAnchor, constant: -4),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    private func setButtonConstraintsWithRightImage() {
        if isCancelButtonNeeded {
            isButtonNeeded(true)
            NSLayoutConstraint.activate([
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            isButtonNeeded(false)
            NSLayoutConstraint.activate([
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    private func setButtonConstraintsWithoutImage() {
        if isCancelButtonNeeded {
            isButtonNeeded(true)
            
            NSLayoutConstraint.activate([
                cancelXButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                cancelXButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                cancelXButton.heightAnchor.constraint(equalToConstant: 40),
                cancelXButton.widthAnchor.constraint(equalToConstant: 40),
            ])
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: cancelXButton.leadingAnchor, constant: -4),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            isButtonNeeded(false)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    private func isButtonNeeded(_ needed: Bool) {
        if needed {
            cancelXButton.alpha = 1
            cancelXButton.isUserInteractionEnabled = true
        } else {
            cancelXButton.alpha = 0
            cancelXButton.isUserInteractionEnabled = false
        }
    }
    
}
