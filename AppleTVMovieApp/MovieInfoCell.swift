//
//  MovieInfoCell.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class MovieInfoCell: UICollectionViewCell {
    private let posterView = UIImageView()
    private let placeholderView = UIImageView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let chipRow = UIStackView()
    private let yearChip = MetadataChip(emphasized: false)
    private let ratingChip = MetadataChip(emphasized: true)
    private let overviewLabel = UILabel()
    private let directorLabel = UILabel()
    private let textStack = UIStackView()

    private var loadTask: Task<Void, Never>?
    private var representedID: Int?

    override var canBecomeFocused: Bool { false }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Movie info is created in code.")
    }

    func configure(movie: Movie, directorLine: String?) {
        representedID = movie.id
        titleLabel.text = movie.title
        yearChip.setText(movie.releaseYear)
        ratingChip.setText(movie.ratingText)
        chipRow.isHidden = yearChip.isHidden && ratingChip.isHidden
        overviewLabel.text = movie.overviewText
        directorLabel.attributedText = Self.directorText(directorLine)
        directorLabel.isHidden = directorLine == nil
        accessibilityLabel = [movie.title, movie.metaText, movie.overviewText, directorLine]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")

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
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        isAccessibilityElement = true

        posterView.translatesAutoresizingMaskIntoConstraints = false
        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.backgroundColor = Theme.posterFill
        posterView.layer.cornerRadius = Theme.posterCornerRadius

        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.image = UIImage(systemName: "film")
        placeholderView.tintColor = UIColor(white: 1, alpha: 0.45)
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)

        eyebrowLabel.attributedText = NSAttributedString(
            string: "MOVIE",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: Theme.secondaryText,
                .kern: 3.5
            ]
        )
        eyebrowLabel.accessibilityLabel = "Movie"

        titleLabel.font = UIFont.systemFont(ofSize: 46, weight: .bold)
        titleLabel.textColor = Theme.primaryText
        titleLabel.numberOfLines = 2

        chipRow.axis = .horizontal
        chipRow.alignment = .center
        chipRow.spacing = 12
        chipRow.addArrangedSubview(yearChip)
        chipRow.addArrangedSubview(ratingChip)

        overviewLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        overviewLabel.textColor = Theme.overviewText
        overviewLabel.numberOfLines = 3

        directorLabel.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        directorLabel.textColor = Theme.primaryText
        directorLabel.numberOfLines = 2
        directorLabel.accessibilityIdentifier = "detail.director"

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 10
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(eyebrowLabel)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(chipRow)
        textStack.addArrangedSubview(overviewLabel)
        textStack.addArrangedSubview(directorLabel)
        textStack.setCustomSpacing(16, after: chipRow)
        textStack.setCustomSpacing(18, after: overviewLabel)

        contentView.addSubview(posterView)
        posterView.addSubview(placeholderView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            posterView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterView.widthAnchor.constraint(equalToConstant: Theme.detailPosterWidth),
            posterView.heightAnchor.constraint(equalToConstant: Theme.detailPosterHeight),

            placeholderView.centerXAnchor.constraint(equalTo: posterView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: posterView.centerYAnchor),
            placeholderView.widthAnchor.constraint(equalToConstant: 64),
            placeholderView.heightAnchor.constraint(equalToConstant: 64),

            textStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            textStack.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 48),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    private static func directorText(_ line: String?) -> NSAttributedString? {
        guard let line, line.hasPrefix("Directed by ") else {
            guard let line else { return nil }
            return NSAttributedString(string: line, attributes: [
                .font: UIFont.systemFont(ofSize: 30, weight: .semibold),
                .foregroundColor: Theme.primaryText
            ])
        }
        let name = String(line.dropFirst("Directed by ".count))
        let text = NSMutableAttributedString(string: "Directed by ", attributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: Theme.secondaryText
        ])
        text.append(NSAttributedString(string: name, attributes: [
            .font: UIFont.systemFont(ofSize: 30, weight: .semibold),
            .foregroundColor: Theme.primaryText
        ]))
        return text
    }
}
