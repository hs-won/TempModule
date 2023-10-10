//
//  File.swift
//
//
//  Created by USER on 2022/07/25.
//

import Combine
import UIKit

extension UITextField {
    var textPublisher: AnyPublisher<String?, Never> {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextField)?.text }
            .eraseToAnyPublisher()
    }
}
