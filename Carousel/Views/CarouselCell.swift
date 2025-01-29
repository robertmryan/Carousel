//
//  CarouselCell.swift
//  Carousel
//
//  Created by Robert Ryan on 1/29/25.
//

import UIKit
import Combine

protocol SelfConfiguringCell {
    static var reuseIdentifier: String { get }
    func configure(with item: CarouselViewController.Download)
}

class CarouselCell: UICollectionViewCell, SelfConfiguringCell {
    static let reuseIdentifier: String = "carouselCell"

    private var downloadTask: AnyCancellable?

    var title: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "Marker Felt", size: 24)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var subtitle: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "Marker Felt", size: 12)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.isUserInteractionEnabled = false
        view.center = view.center
        view.setProgress(0.0, animated: false)
        view.tintColor = .red
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var stackView: UIView = {
        let stack = UIView()
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.backgroundColor = .gray
        return stack
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                highlight()
            } else {
                unhighlight()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        downloadTask = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("error")
    }

    func setupViews() {
        stackView.addSubview(progressView)
        stackView.addSubview(title)
        stackView.addSubview(subtitle)
        contentView.addSubview(stackView)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            title.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            title.topAnchor.constraint(equalTo: stackView.topAnchor),
            title.bottomAnchor.constraint(equalTo: subtitle.topAnchor),

            subtitle.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            subtitle.bottomAnchor.constraint(equalTo: progressView.topAnchor),

            progressView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }

    private func animateScale(to scale: CGFloat, duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.5,
            options: [.beginFromCurrentState]) {
                self.stackView.transform = .init(scaleX: scale, y: scale)
            }
    }

    func highlight() {
        animateScale(to: 0.9, duration: 0.4)
    }

    func unhighlight() {
        animateScale(to: 1, duration: 0.38)
    }

    func configure(with download: CarouselViewController.Download) {
        title.text = download.item.title

        downloadTask = download.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.subtitle.text = state.description
                let progress: Float = switch state {
                    case .inProgress(let progress): progress
                    default: 0
                }
                self?.progressView.setProgress(progress, animated: true)
            }
    }
}
