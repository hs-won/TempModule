//
//  File.swift
//
//
//  Created by USER on 2022/07/25.
//

import Combine
import UIKit

class UIControlSubscription<S: Subscriber, T: UIControl>: Subscription where Never == S.Failure, T == S.Input {
    private var subscriber: S?
    private let uiControl: T

    init(_ subscriber: S, _ uiControl: T, _ event: T.Event) {
        self.subscriber = subscriber
        self.uiControl = uiControl

        uiControl.addTarget(self, action: #selector(self.doAction), for: event)
    }

    func request(_: Subscribers.Demand) {}

    func cancel() {
        self.subscriber = nil
    }

    @objc func doAction() {
        _ = self.subscriber?.receive(self.uiControl)
    }
}

struct UIControlPublisher<T: UIControl>: Publisher {
    typealias Output = T
    typealias Failure = Never
    typealias Event = T.Event

    private let uiControl: T
    private let event: Event

    init(uiControl: T, event: Event) {
        self.uiControl = uiControl
        self.event = event
    }

    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, T == S.Input {
        let subscription = UIControlSubscription(subscriber, self.uiControl, self.event)
        subscriber.receive(subscription: subscription)
    }
}

extension UIControl {
    func publisher(event: Event) -> UIControlPublisher<UIControl> {
        UIControlPublisher(uiControl: self, event: event)
    }
}
