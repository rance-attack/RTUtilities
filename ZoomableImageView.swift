import UIKit

final class ZoomableImageView: UIImageView {
    private var scale: CGFloat = 1
    private var pinchOffset: CGPoint = .zero
    private var panOffset: CGPoint = .zero
    private var isResetting = false

    private lazy var pinchRecognizer: UIPinchGestureRecognizer = {
        let recognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        recognizer.delegate = self
        return recognizer
    }()

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        recognizer.minimumNumberOfTouches = 2
        recognizer.maximumNumberOfTouches = 2
        recognizer.delegate = self
        return recognizer
    }()

    private weak var dimView: UIView?
    private weak var imageView: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(pinchRecognizer)
        addGestureRecognizer(panRecognizer)
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state != .ended else {
            return reset()
        }

        if recognizer.state == .began {
            showDimView()

            let pinchPoint = recognizer.location(in: self)
            pinchOffset = CGPoint(
                x: pinchPoint.x - bounds.midX,
                y: pinchPoint.y - bounds.midY)
        }

        recognizer.scale = max(recognizer.scale, 1)
        scale = recognizer.scale
        transform()
    }

    @objc private func didPan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state != .ended else {
            return reset()
        }

        if recognizer.state == .began {
            showDimView()
        }

        panOffset = recognizer.translation(in: self)
        transform()
    }

    private func transform() {
        imageView?.transform = CGAffineTransform(translationX: -pinchOffset.x, y: -pinchOffset.y)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: pinchOffset.x, y: pinchOffset.y))
            .concatenating(CGAffineTransform(translationX: panOffset.x, y: panOffset.y))
    }

    private func reset() {
        guard !isResetting else { return }
        isResetting = true
        scale = 1
        pinchRecognizer.scale = scale
        pinchOffset = .zero
        panOffset = .zero
        panRecognizer.setTranslation(panOffset, in: self)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.imageView?.transform = .identity
                self.dimView?.backgroundColor = .clear
            },
            completion: { _ in
                self.dimView?.removeFromSuperview()
                self.alpha = 1
                self.isResetting = false
            })
    }

    private func showDimView() {
        guard
            dimView == nil,
            let window = window
        else { return }

        alpha = 0

        let dimView = UIView()
        self.dimView = dimView
        dimView.frame = UIScreen.main.bounds
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        window.addSubview(dimView)

        let imageView = UIImageView(image: image)
        self.imageView = imageView
        imageView.frame = window.convert(frame, from: superview)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = clipsToBounds
        dimView.addSubview(imageView)
    }
}

extension ZoomableImageView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        otherGestureRecognizer == pinchRecognizer || otherGestureRecognizer == panRecognizer
    }
}
