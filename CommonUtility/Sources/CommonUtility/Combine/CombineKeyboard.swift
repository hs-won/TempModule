import Combine
import UIKit

final class CombineKeyboard: NSObject {
    typealias KeyboardFrame = (frame: CGRect, visibleHeight: CGFloat)
    
    static let shared = CombineKeyboard()
    let publisher = CurrentValueSubject<KeyboardFrame, Never>((CGRect.zero, 0))
    
    private var cancellables = Set<AnyCancellable>()
    private let panGestureSubject = PassthroughSubject<UIPanGestureRecognizer, Never>()
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    override private init() {
        super.init()
        
        let willChangePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        let keyboardChangePublisher = Publishers.Merge(willChangePublisher, willHidePublisher)
            .map { notification -> CGRect in
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? CGRect.zero
                return frame
            }
        
        let panGesturePublisher = self.panGestureSubject
            .map { [weak self] gestureRecognizer -> CGRect? in
                guard let self = self,
                      case .changed = gestureRecognizer.state,
                      let window = UIApplication.shared.windows.first,
                      self.publisher.value.frame.origin.y < UIScreen.main.bounds.height
                else {
                    return nil
                }
                
                let origin = gestureRecognizer.location(in: window)
                var newFrame = self.publisher.value.frame
                newFrame.origin.y = max(origin.y, UIScreen.main.bounds.height - newFrame.height)
                return newFrame
            }
            .compactMap { $0 }
        
        Publishers.Merge(keyboardChangePublisher, panGesturePublisher)
            .map {
                let height = UIScreen.main.bounds.height - $0.origin.y
                return (frame: $0, visibleHeight: height)
            }
            .subscribe(self.publisher)
            .store(in: &self.cancellables)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        panGestureRecognizer.delegate = self
        UIApplication.shared.windows.first?.addGestureRecognizer(panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer
    }
    
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        self.panGestureSubject.send(sender)
    }
}

extension CombineKeyboard: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: gestureRecognizer.view)
        var view = gestureRecognizer.view?.hitTest(location, with: nil)
        while let candidate = view {
            if let scrollView = candidate as? UIScrollView,
               case .interactive = scrollView.keyboardDismissMode
            {
                return true
            }
            view = candidate.superview
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === self.panGestureRecognizer
    }
}
