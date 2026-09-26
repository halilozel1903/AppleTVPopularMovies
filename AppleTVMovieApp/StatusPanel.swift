//
//  StatusPanel.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class StatusPanel: UIView {
    let retryButton = UIButton(type: .system)

    private let well = UIView()
    private let symbolView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        well.backgroundColor = Theme.posterFill
        well.layer.cornerRadius = 52
        well.translatesAutoresizingMaskIntoConstraints = false

        symbolView.tintColor = Theme.gold
        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)
        symbolView.translatesAutoresizingMaskIntoConstraints = false

        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: .semibold)
        titleLabel.textColor = Theme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        detailLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        detailLabel.textColor = Theme.secondaryText
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.backdrop
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 36, bottom: 16, trailing: 36)
        retryButton.configuration = config

        well.addSubview(symbolView)
        well.addSubview(spinner)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(well)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)
        stack.addArrangedSubview(retryButton)
        stack.setCustomSpacing(28, after: detailLabel)
        addSubview(stack)

        NSLayoutConstraint.activate([
            well.widthAnchor.constraint(equalToConstant: 104),
            well.heightAnchor.constraint(equalToConstant: 104),
            symbolView.centerXAnchor.constraint(equalTo: well.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: well.centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 48),
            symbolView.heightAnchor.constraint(equalToConstant: 48),
            spinner.centerXAnchor.constraint(equalTo: well.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: well.centerYAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 760),
            detailLabel.widthAnchor.constraint(equalToConstant: 720)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Status panels are created in code.")
    }

    func setStatusIdentifier(_ identifier: String) {
        titleLabel.accessibilityIdentifier = identifier
    }

    func setRetryIdentifier(_ identifier: String) {
        retryButton.accessibilityIdentifier = identifier
    }

    func showLoading(title: String, detail: String) {
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = detail.isEmpty
        symbolView.isHidden = true
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
    }

    func showNotice(symbol: String, title: String, detail: String, retry: Bool) {
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = detail.isEmpty
        symbolView.image = UIImage(systemName: symbol)
        symbolView.isHidden = false
        spinner.stopAnimating()
        spinner.isHidden = true
        retryButton.isHidden = !retry
    }
}
