//
//  ViewController.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

private struct RailPlacement: Hashable {
    let rail: MovieRail
    let movie: Movie

    static func == (lhs: RailPlacement, rhs: RailPlacement) -> Bool {
        lhs.rail == rhs.rail && lhs.movie.id == rhs.movie.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rail)
        hasher.combine(movie.id)
    }
}

final class ViewController: UIViewController, UICollectionViewDelegate {
    private struct LoadedRail {
        let rail: MovieRail
        let movies: [Movie]
    }

    private let service = MovieService()
    private var loadTask: Task<Void, Never>?
    private var rails: [LoadedRail] = []
    private var appliedSideInset: CGFloat = -1
    private var dataSource: UICollectionViewDiffableDataSource<MovieRail, RailPlacement>!

    private let gradientLayer = CAGradientLayer()
    private let topStack = UIStackView()
    private let headerStack = UIStackView()
    private let titleRow = UIStackView()
    private let heroStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let screenTitleLabel = UILabel()
    private let countLabel = UILabel()
    private let focusedTitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let overviewLabel = UILabel()
    private let statusContainer = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var collectionView: UICollectionView!

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        guard isViewLoaded, collectionView != nil else {
            return super.preferredFocusEnvironments
        }
        if !retryButton.isHidden {
            return [retryButton]
        }
        if !collectionView.isHidden {
            return [collectionView]
        }
        return super.preferredFocusEnvironments
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Movies"
        overrideUserInterfaceStyle = .dark
        configureAppearance()
        configureHeader()
        configureHero()
        configureStatus()
        configureCollection()
        configureDataSource()
        installConstraints()
        showLoading()
        loadMovies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        installShelfLayoutIfNeeded()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        guard let indexPath = context.nextFocusedIndexPath,
              let placement = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator.addCoordinatedAnimations { [weak self] in
            self?.showFocusedMovie(placement.movie, in: placement.rail)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let placement = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = MovieDetailViewController(movie: placement.movie, service: service)
        navigationController?.pushViewController(detail, animated: true)
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    private func configureAppearance() {
        view.backgroundColor = Theme.backdrop
        gradientLayer.colors = [Theme.backdropTop.cgColor, Theme.backdrop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureHeader() {
        setEyebrow("Movies")

        screenTitleLabel.text = "Movies"
        screenTitleLabel.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        screenTitleLabel.textColor = Theme.primaryText
        screenTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        countLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        countLabel.textColor = Theme.secondaryText
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 16
        titleRow.addArrangedSubview(screenTitleLabel)
        titleRow.addArrangedSubview(spacer)
        titleRow.addArrangedSubview(countLabel)

        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 6
        headerStack.addArrangedSubview(eyebrowLabel)
        headerStack.addArrangedSubview(titleRow)
    }

    private func configureHero() {
        focusedTitleLabel.font = UIFont.systemFont(ofSize: 42, weight: .semibold)
        focusedTitleLabel.textColor = Theme.primaryText
        focusedTitleLabel.numberOfLines = 1
        focusedTitleLabel.lineBreakMode = .byTruncatingTail
        focusedTitleLabel.isAccessibilityElement = false

        metaLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        metaLabel.textColor = Theme.gold
        metaLabel.isAccessibilityElement = false

        overviewLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        overviewLabel.textColor = Theme.overviewText
        overviewLabel.numberOfLines = 2
        overviewLabel.lineBreakMode = .byTruncatingTail
        overviewLabel.isAccessibilityElement = false

        heroStack.axis = .vertical
        heroStack.alignment = .fill
        heroStack.spacing = 8
        heroStack.addArrangedSubview(focusedTitleLabel)
        heroStack.addArrangedSubview(metaLabel)
        heroStack.addArrangedSubview(overviewLabel)
        heroStack.setCustomSpacing(14, after: metaLabel)
        heroStack.isHidden = true
    }

    private func configureStatus() {
        spinner.color = .white
        spinner.hidesWhenStopped = true

        statusLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        statusLabel.textColor = Theme.primaryText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 760
        statusLabel.accessibilityIdentifier = "catalog.status"

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.backdrop
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 36, bottom: 16, trailing: 36)
        retryButton.configuration = config
        retryButton.accessibilityIdentifier = "catalog.retry"
        retryButton.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)

        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.spacing = 22
        statusContainer.addArrangedSubview(spinner)
        statusContainer.addArrangedSubview(statusLabel)
        statusContainer.addArrangedSubview(retryButton)
    }

    private func configureCollection() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout(sideInset: 90))
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "catalog.rails"
        appliedSideInset = 90
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<MovieCell, RailPlacement> { cell, _, placement in
            cell.configure(with: placement.movie)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<RailHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            let title = self?.rails.indices.contains(indexPath.section) == true
                ? self?.rails[indexPath.section].rail.title ?? ""
                : ""
            header.configure(title: title)
        }
        dataSource = UICollectionViewDiffableDataSource<MovieRail, RailPlacement>(collectionView: collectionView) {
            collectionView, indexPath, placement in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: placement)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }

    private func installConstraints() {
        topStack.axis = .vertical
        topStack.alignment = .fill
        topStack.spacing = 28
        topStack.addArrangedSubview(headerStack)
        topStack.addArrangedSubview(heroStack)

        let arrangedViews: [UIView] = [topStack, collectionView, statusContainer]
        arrangedViews.forEach { item in
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            topStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            statusContainer.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            statusContainer.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            statusContainer.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor),
            statusContainer.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 760)
        ])
    }

    private func installShelfLayoutIfNeeded() {
        let side = view.safeAreaInsets.left
        guard side > 0, side != appliedSideInset else { return }
        appliedSideInset = side
        collectionView.setCollectionViewLayout(makeLayout(sideInset: side), animated: false)
    }

    private func makeLayout(sideInset: CGFloat) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            Self.railSection(sideInset: sideInset)
        }
        layout.configuration.interSectionSpacing = 4
        return layout
    }

    private static func railSection(sideInset: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.posterWidth),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.posterWidth),
            heightDimension: .absolute(Theme.cardHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Theme.shelfSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: sideInset, bottom: 24, trailing: sideInset)
        section.contentInsetsReference = .none
        section.supplementariesFollowContentInsets = true

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(Theme.railHeaderHeight)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func loadMovies() {
        loadTask?.cancel()
        showLoading()
        loadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            async let popular = self.fetchRail(.popular)
            async let topRated = self.fetchRail(.topRated)
            async let nowPlaying = self.fetchRail(.nowPlaying)
            async let upcoming = self.fetchRail(.upcoming)
            let loads = await [popular, topRated, nowPlaying, upcoming]
            guard !Task.isCancelled else { return }
            self.apply(loads)
        }
    }

    private func fetchRail(_ rail: MovieRail) async -> (MovieRail, Result<[Movie], Error>) {
        do {
            let movies = try await service.movies(in: rail)
            return (rail, .success(movies))
        } catch {
            return (rail, .failure(error))
        }
    }

    private func apply(_ loads: [(MovieRail, Result<[Movie], Error>)]) {
        var loaded: [LoadedRail] = []
        var firstFailure: Error?
        for rail in MovieRail.allCases {
            guard let result = loads.first(where: { $0.0 == rail })?.1 else { continue }
            switch result {
            case .success(let movies):
                let unique = uniqueMovies(movies)
                if !unique.isEmpty {
                    loaded.append(LoadedRail(rail: rail, movies: unique))
                }
            case .failure(let error):
                if firstFailure == nil {
                    firstFailure = error
                }
            }
        }

        if !loaded.isEmpty {
            showRails(loaded)
            return
        }
        if let firstFailure {
            showMessage(message(for: firstFailure), retry: true)
            return
        }
        showMessage("No movies to show right now.", retry: true)
    }

    private func uniqueMovies(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        return movies.filter { seen.insert($0.id).inserted }
    }

    private func showRails(_ loaded: [LoadedRail]) {
        rails = loaded
        statusContainer.isHidden = true
        spinner.stopAnimating()
        collectionView.isHidden = false
        heroStack.isHidden = false

        if let first = loaded.first?.movies.first, let rail = loaded.first?.rail {
            showFocusedMovie(first, in: rail)
        }

        var snapshot = NSDiffableDataSourceSnapshot<MovieRail, RailPlacement>()
        for entry in loaded {
            snapshot.appendSections([entry.rail])
            let items = entry.movies.map { RailPlacement(rail: entry.rail, movie: $0) }
            snapshot.appendItems(items, toSection: entry.rail)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
        refreshFocus()
    }

    private func showFocusedMovie(_ movie: Movie, in rail: MovieRail) {
        focusedTitleLabel.text = movie.title
        metaLabel.text = movie.metaText
        metaLabel.isHidden = movie.metaText.isEmpty
        overviewLabel.text = movie.overviewText
        setEyebrow(rail.title)
        let count = rails.first { $0.rail == rail }?.movies.count ?? 0
        countLabel.isHidden = count == 0
        countLabel.text = count == 1 ? "1 title" : "\(count) titles"
    }

    private func setEyebrow(_ text: String) {
        eyebrowLabel.attributedText = NSAttributedString(
            string: text.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: Theme.secondaryText,
                .kern: 3.5
            ]
        )
        eyebrowLabel.accessibilityLabel = text
    }

    private func showLoading() {
        collectionView.isHidden = true
        heroStack.isHidden = true
        countLabel.isHidden = true
        statusContainer.isHidden = false
        statusLabel.text = "Loading movies…"
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
        refreshFocus()
    }

    private func showMessage(_ text: String, retry: Bool) {
        collectionView.isHidden = true
        heroStack.isHidden = true
        countLabel.isHidden = true
        statusContainer.isHidden = false
        statusLabel.text = text
        spinner.stopAnimating()
        spinner.isHidden = true
        retryButton.isHidden = !retry
        refreshFocus()
    }

    private func message(for error: Error) -> String {
        if let serviceError = error as? MovieServiceError {
            return serviceError.localizedDescription
        }
        if error is CancellationError {
            return "Something went wrong while loading movies."
        }
        if error is URLError {
            return "Check the network connection and try again."
        }
        return "Something went wrong while loading movies."
    }

    private func refreshFocus() {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    @objc private func retryTapped() {
        loadMovies()
    }
}
