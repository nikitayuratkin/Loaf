//
//  Loaf.swift
//  Loaf
//
//  Created by Mat Schmid on 2019-02-04.
//  Copyright © 2019 Mat Schmid. All rights reserved.
//

import UIKit


protocol LoafDelegate: AnyObject {
    func loafDidDismiss()
}

final public class Loaf {
    
    // MARK: - Specifiers
    
    // Reason a Loaf was dismissed
    public enum DismissalReason {
        /// Включает 3 обработки дисмисса (по тапу, по свайпу, по таймауту)
        case all
        /// Дисмисс по нажатию на кнопку `cancelXButton` и свайпу. По тапу колбэк.
        case interactive
    }
    
    /// Define a custom style for the loaf.
    public struct Style {
        /// Specifies the position of the icon on the loaf. (Default is `.left`)
        ///
        /// - left: The icon will be on the left of the text
        /// - right: The icon will be on the right of the text
        public enum IconAlignment {
            case left
            case right
        }
        
        /// Specifies the width of the Loaf. (Default is `.fixed(280)`)
        ///
        /// - fixed: Specified as pixel size. i.e. 280
        /// - screenPercentage: Specified as a ratio to the screen size. This value must be between 0 and 1. i.e. 0.8
        public enum Width {
            case fixed(CGFloat)
            case screenPercentage(CGFloat)
        }
        
        /// The background color of the loaf.
        let backgroundColor: UIColor
        
        /// The color of the label's text
        let textColor: UIColor
        
        /// The color of the icon (Assuming it's rendered as template)
        let tintColor: UIColor
        
        /// The font of the label
        let font: UIFont
        
        /// The icon on the loaf
        let icon: UIImage?
        
        /// The alignment of the text within the Loaf
        let textAlignment: NSTextAlignment
        
        /// The position of the icon
        let iconAlignment: IconAlignment
        
        /// The width of the loaf
        let width: Width
        
        public init(
            backgroundColor: UIColor,
            textColor: UIColor = .white,
            tintColor: UIColor = .white,
            font: UIFont = .systemFont(ofSize: 14, weight: .medium),
            icon: UIImage? = Icon.info,
            textAlignment: NSTextAlignment = .left,
            iconAlignment: IconAlignment = .left,
            width: Width = .fixed(280)) {
                self.backgroundColor = backgroundColor
                self.textColor = textColor
                self.tintColor = tintColor
                self.font = font
                self.icon = icon
                self.textAlignment = textAlignment
                self.iconAlignment = iconAlignment
                self.width = width
            }
    }
    
    /// Defines the loaf's status. (Default is `.info`)
    ///
    /// - success: Represents a success message
    /// - error: Represents an error message
    /// - warning: Represents a warning message
    /// - info: Represents an info message
    /// - custom: Represents a custom loaf with a specified style.
    public enum State {
        case success
        case error
        case warning
        case info
        case withCancelButton
        case custom(Style)
    }
    
    /// Defines the loaction to display the loaf. (Default is `.bottom`)
    ///
    /// - top: Top of the display
    /// - bottom: Bottom of the display
    public enum Location {
        case top
        case bottom
    }
    
    /// Defines either the presenting or dismissing direction of loaf. (Default is `.vertical`)
    ///
    /// - left: To / from the left
    /// - right: To / from the right
    /// - vertical: To / from the top or bottom (depending on the location of the loaf)
    public enum Direction {
        case left
        case right
        case vertical
    }
    
    /// Defines the duration of the loaf presentation. (Default is .`avergae`)
    ///
    /// - short: 2 seconds
    /// - average: 4 seconds
    /// - long: 8 seconds
    /// - custom: A custom duration (usage: `.custom(5.0)`)
    public enum Duration {
        case short
        case average
        case long
        case custom(TimeInterval)
        
        var length: TimeInterval {
            switch self {
            case .short:   return 1.5
            case .average: return 3.0
            case .long:    return 7.0
            case .custom(let timeInterval):
                return timeInterval
            }
        }
    }
    
    /// Icons used in basic states
    public enum Icon {
        public static let success = Icons.imageOfSuccess().withRenderingMode(.alwaysTemplate)
        public static let error = Icons.imageOfError().withRenderingMode(.alwaysTemplate)
        public static let warning = Icons.imageOfWarning().withRenderingMode(.alwaysTemplate)
        public static let info = Icons.imageOfInfo().withRenderingMode(.alwaysTemplate)
        public static let closeIcon = UIImage(named: "cancelIcon", in: .module, compatibleWith: nil)
    }
    
    // MARK: - Properties
    public typealias LoafCompletionHandler = ((DismissalReason) -> Void)?
    var message: String
    var dismissalReason: DismissalReason
    var state: State
    var location: Location
    var duration: Duration = .average
    var presentingDirection: Direction
    var dismissingDirection: Direction
    var completionHandler: LoafCompletionHandler = nil
    weak var sender: UIViewController?
    
    // MARK: - Public methods
    public init(_ message: String,
                dismissalReason: DismissalReason = .all,
                state: State = .info,
                location: Location = .bottom,
                presentingDirection: Direction = .vertical,
                dismissingDirection: Direction = .vertical,
                sender: UIViewController) {
        self.message = message
        self.dismissalReason = dismissalReason
        self.state = state
        self.location = location
        self.presentingDirection = presentingDirection
        self.dismissingDirection = dismissingDirection
        self.sender = sender
    }
    
    /// Show the loaf for a specified duration. (Default is `.average`)
    ///
    /// - Parameter duration: Length the loaf will be presented
    public func show(_ duration: Duration = .average, completionHandler: LoafCompletionHandler = nil) {
        self.duration = duration
        self.completionHandler = completionHandler
        LoafManager.shared.queueAndPresent(self)
    }
    
    /// Manually dismiss a currently presented Loaf
    ///
    /// - Parameter animated: Whether the dismissal will be animated
    public static func dismiss(sender: UIViewController, animated: Bool = true){
        guard LoafManager.shared.isPresenting else { return }
        guard let vc = sender.presentedViewController as? LoafViewController else { return }
        vc.dismiss(animated: animated) {
            vc.delegate?.loafDidDismiss()
        }
    }
}

final fileprivate class LoafManager: LoafDelegate {
    static let shared = LoafManager()
    
    fileprivate var queue = Queue<Loaf>()
    fileprivate var isPresenting = false
    
    fileprivate func queueAndPresent(_ loaf: Loaf) {
        queue.enqueue(loaf)
        presentIfPossible()
    }
    
    func loafDidDismiss() {
        isPresenting = false
        presentIfPossible()
    }
    
    fileprivate func presentIfPossible() {
        guard isPresenting == false, let loaf = queue.dequeue(), let sender = loaf.sender else { return }
        isPresenting = true
        let loafVC = LoafViewController(loaf)
        loafVC.delegate = self
        sender.presentToast(loafVC)
    }
}

private struct Queue<T> {
    fileprivate var array = [T]()
    
    mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    mutating func dequeue() -> T? {
        if array.isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
}

