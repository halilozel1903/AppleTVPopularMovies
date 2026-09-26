//
//  CastMemberCell.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class CastMemberCell: UICollectionViewCell {
    private let shadowView = UIView()
    private let photoView = UIImageView()
    private let placeholderView = UIImageView()
    private let nameLabel = UILabel()
    private let characterLabel = UILabel()

    private var loadTask: Task<Void, Never>?
    private var representedID: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Cast cells are created in code.")
    }

    func configure(with person: CastMember) {
        representedID = person.id
        nameLabel.text = person.name
        characterLabel.text = person.characterText
        accessibilityLabel = person.accessibilitySummary
        photoView.image = nil
        placeholderView.isHidden = false
        loadTask?.cancel()

        guard let url = person.profileURL else { return }
        let personID = person.id
        loadTask = Task { @MainActor [weak self] in
            guard let image = try? await ImageLoader.shared.image(for: url) else { return }
            guard let self = self, !Task.isCancelled, self.representedID == personID else { return }
            self.photoView.image = image
            self.placeholderView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        loadTask = nil
        representedID = nil
        photoView.image = nil
        placeholderView.isHidden = false
        transform = .identity
        layer.zPosition = 0
        photoView.layer.borderWidth = 0
        shadowView.layer.shadowOpacity = 0
        nameLabel.textColor = Theme.secondaryText
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
            self.photoView.layer.borderWidth = focused ? 4 : 0
            self.shadowView.layer.shadowOpacity = focused ? 0.42 : 0
            self.nameLabel.textColor = focused ? Theme.primaryText : Theme.secondaryText
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
        shadowView.layer.shadowRadius = 18
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 12)
        shadowView.layer.shadowOpacity = 0

        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.backgroundColor = Theme.posterFill
        photoView.layer.cornerRadius = Theme.posterCornerRadius
        photoView.layer.borderColor = Theme.focusRing.cgColor
        photoView.layer.borderWidth = 0

        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.image = UIImage(systemName: "person.fill")
        placeholderView.tintColor = UIColor(white: 1, alpha: 0.45)
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textColor = Theme.secondaryText
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.isAccessibilityElement = false

        characterLabel.translatesAutoresizingMaskIntoConstraints = false
        characterLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        characterLabel.textColor = Theme.secondaryText
        characterLabel.numberOfLines = 1
        characterLabel.lineBreakMode = .byTruncatingTail
        characterLabel.isAccessibilityElement = false

        contentView.addSubview(shadowView)
        shadowView.addSubview(photoView)
        photoView.addSubview(placeholderView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(characterLabel)

        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: Theme.castPhotoHeight),

            photoView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),

            placeholderView.centerXAnchor.constraint(equalTo: photoView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: photoView.centerYAnchor),
            placeholderView.widthAnchor.constraint(equalToConstant: 48),
            placeholderView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: shadowView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 52),

            characterLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            characterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            characterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            characterLabel.heightAnchor.constraint(equalToConstant: 26)
        ])
    }
}
