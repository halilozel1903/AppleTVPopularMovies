//
//  MovieCell.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class MovieCell: UICollectionViewCell {
    private let shadowView = UIView()
    private let posterView = UIImageView()
    private let placeholderView = UIImageView()
    private let titleLabel = UILabel()

    private var loadTask: Task<Void, Never>?
    private var representedID: Int?
    private var posterHeightConstraint: NSLayoutConstraint?
    private var titleHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(
        with movie: Movie,
        posterHeight: CGFloat = Theme.posterHeight,
        titleHeight: CGFloat = Theme.titleHeight
    ) {
        posterHeightConstraint?.constant = posterHeight
        titleHeightConstraint?.constant = titleHeight
        representedID = movie.id
        titleLabel.text = movie.title
        accessibilityLabel = movie.accessibilitySummary
        posterView.image = nil
        placeholderView.isHidden = false
        loadTask?.cancel()

        guard let url = movie.posterURL else { return }
        let movieID = movie.id
        loadTask = Task { @MainActor [weak self] in
            guard let image = try? await ImageLoader.shared.image(for: url) else { return }
            guard let self = self, !Task.isCancelled, self.representedID == movieID else { return }
            self.posterView.image = image
            self.placeholderView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        loadTask = nil
        representedID = nil
        posterView.image = nil
        placeholderView.isHidden = false
        transform = .identity
        layer.zPosition = 0
        posterView.layer.borderWidth = 0
        shadowView.layer.shadowOpacity = 0
        titleLabel.textColor = Theme.secondaryText
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(
            roundedRect: shadowView.bounds,
            cornerRadius: Theme.posterCornerRadius
        ).cgPath
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let focused = isFocused
        layer.zPosition = focused ? 8 : 0
        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self = self else { return }
            let scale: CGFloat = focused ? Theme.focusScale : 1
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.posterView.layer.borderWidth = focused ? Theme.focusRingWidth : 0
            self.shadowView.layer.shadowOpacity = focused ? 0.42 : 0
            self.titleLabel.textColor = focused ? Theme.primaryText : Theme.secondaryText
        }
    }

    private func setup() {
        clipsToBounds = false
        contentView.clipsToBounds = false
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        isAccessibilityElement = true

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowRadius = 22
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 16)
        shadowView.layer.shadowOpacity = 0

        posterView.translatesAutoresizingMaskIntoConstraints = false
        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.backgroundColor = Theme.posterFill
        posterView.layer.cornerRadius = Theme.posterCornerRadius
        posterView.layer.borderColor = Theme.focusRing.cgColor
        posterView.layer.borderWidth = 0

        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.image = UIImage(systemName: "film")
        placeholderView.tintColor = UIColor(white: 1, alpha: 0.45)
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = Theme.secondaryText
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isAccessibilityElement = false

        contentView.addSubview(shadowView)
        shadowView.addSubview(posterView)
        posterView.addSubview(placeholderView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            posterView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            posterView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            posterView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),

            placeholderView.centerXAnchor.constraint(equalTo: posterView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: posterView.centerYAnchor),
            placeholderView.widthAnchor.constraint(equalToConstant: 56),
            placeholderView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.topAnchor.constraint(equalTo: shadowView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        let posterHeight = shadowView.heightAnchor.constraint(equalToConstant: Theme.posterHeight)
        let titleHeight = titleLabel.heightAnchor.constraint(equalToConstant: Theme.titleHeight)
        posterHeight.isActive = true
        titleHeight.isActive = true
        posterHeightConstraint = posterHeight
        titleHeightConstraint = titleHeight
    }
}
