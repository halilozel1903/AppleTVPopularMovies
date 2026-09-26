//
//  MovieDetailViewController.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class MovieDetailViewController: UIViewController, UICollectionViewDelegate {
    private enum DetailSection: Hashable {
        case summary
        case cast
        case similar
    }

    private enum DetailItem: Hashable {
        case summary
        case person(CastMember)
        case similar(Movie)
        case note(DetailNote)
    }

    private enum DetailNote: Hashable {
        case castEmpty
        case castFailed
        case similarEmpty
        case similarFailed

        var text: String {
            switch self {
            case .castEmpty:
                return "No cast listed."
            case .castFailed:
                return "Cast isn't available right now."
            case .similarEmpty:
                return "No similar titles right now."
            case .similarFailed:
                return "Similar titles aren't available right now."
            }
        }
    }

    private let preview: Movie
    private let service: MovieService
    private var loadTask: Task<Void, Never>?
    private var displayedMovie: Movie?
    private var directorLine: String?
    private var castMembers: [CastMember] = []
    private var castNote: DetailNote?
    private var similarMovies: [Movie] = []
    private var similarNote: DetailNote?
    private var appliedSideInset: CGFloat = -1
    private var dataSource: UICollectionViewDiffableDataSource<DetailSection, DetailItem>!

    private let gradientLayer = CAGradientLayer()
    private let backButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private let statusContainer = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    init(movie: Movie, service: MovieService) {
        self.preview = movie
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Movie detail is created in code.")
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if !retryButton.isHidden {
            return [retryButton]
        }
        if isViewLoaded, collectionView != nil, !collectionView.isHidden {
            return [collectionView]
        }
        return [backButton]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = preview.title
        overrideUserInterfaceStyle = .dark
        configureAppearance()
        configureBackButton()
        configureCollection()
        configureDataSource()
        configureStatus()
        installConstraints()
        loadDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        installLayoutIfNeeded()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self = self else { return }
            for button in [self.backButton, self.retryButton] {
                let scale: CGFloat = button.isFocused ? 1.06 : 1
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer { collectionView.deselectItem(at: indexPath, animated: false) }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        guard case .similar(let movie) = item else { return }
        let detail = MovieDetailViewController(movie: movie, service: service)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func configureAppearance() {
        view.backgroundColor = Theme.backdrop
        gradientLayer.colors = [Theme.backdropTop.cgColor, Theme.backdrop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureBackButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Movies"
        config.image = UIImage(systemName: "chevron.backward")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.14)
        config.baseForegroundColor = Theme.primaryText
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 26)
        backButton.configuration = config
        backButton.accessibilityLabel = "Back to movies"
        backButton.accessibilityIdentifier = "detail.back"
        backButton.addTarget(self, action: #selector(backTapped), for: .primaryActionTriggered)
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
        collectionView.accessibilityIdentifier = "detail.collection"
        collectionView.isHidden = true
        appliedSideInset = 90
    }

    private func configureDataSource() {
        let summaryRegistration = UICollectionView.CellRegistration<MovieInfoCell, DetailItem> { [weak self] cell, _, _ in
            guard let self = self, let movie = self.displayedMovie else { return }
            cell.configure(movie: movie, directorLine: self.directorLine)
        }
        let castRegistration = UICollectionView.CellRegistration<CastMemberCell, DetailItem> { cell, _, item in
            guard case .person(let person) = item else { return }
            cell.configure(with: person)
        }
        let similarRegistration = UICollectionView.CellRegistration<MovieCell, DetailItem> { cell, _, item in
            guard case .similar(let movie) = item else { return }
            cell.configure(
                with: movie,
                posterHeight: Theme.relatedPosterHeight,
                titleHeight: Theme.relatedTitleHeight
            )
        }
        let noteRegistration = UICollectionView.CellRegistration<DetailNoteCell, DetailItem> { cell, _, item in
            guard case .note(let note) = item else { return }
            cell.configure(note.text)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<RailHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            header.configure(title: self?.headerTitle(for: indexPath.section) ?? "")
        }

        dataSource = UICollectionViewDiffableDataSource<DetailSection, DetailItem>(collectionView: collectionView) {
            collectionView, indexPath, item in
            switch item {
            case .summary:
                return collectionView.dequeueConfiguredReusableCell(using: summaryRegistration, for: indexPath, item: item)
            case .person:
                return collectionView.dequeueConfiguredReusableCell(using: castRegistration, for: indexPath, item: item)
            case .similar:
                return collectionView.dequeueConfiguredReusableCell(using: similarRegistration, for: indexPath, item: item)
            case .note:
                return collectionView.dequeueConfiguredReusableCell(using: noteRegistration, for: indexPath, item: item)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }

    private func configureStatus() {
        spinner.color = .white
        spinner.hidesWhenStopped = true

        statusLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        statusLabel.textColor = Theme.primaryText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 760
        statusLabel.accessibilityIdentifier = "detail.status"

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.backdrop
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 36, bottom: 16, trailing: 36)
        retryButton.configuration = config
        retryButton.accessibilityIdentifier = "detail.retry"
        retryButton.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)

        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.spacing = 22
        statusContainer.addArrangedSubview(spinner)
        statusContainer.addArrangedSubview(statusLabel)
        statusContainer.addArrangedSubview(retryButton)
    }

    private func installConstraints() {
        [backButton, collectionView, statusContainer].forEach { item in
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor),

            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            statusContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 24),
            statusLabel.widthAnchor.constraint(equalToConstant: 760)
        ])
    }

    private func installLayoutIfNeeded() {
        let side = view.safeAreaInsets.left
        guard side > 0, side != appliedSideInset else { return }
        appliedSideInset = side
        collectionView.setCollectionViewLayout(makeLayout(sideInset: side), animated: false)
    }

    private func makeLayout(sideInset: CGFloat) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else {
                return Self.summarySection(sideInset: sideInset)
            }
            return self.sectionLayout(for: sectionIndex, sideInset: sideInset)
        }
    }

    private func sectionLayout(for sectionIndex: Int, sideInset: CGFloat) -> NSCollectionLayoutSection {
        guard let section = dataSource?.sectionIdentifier(for: sectionIndex) else {
            return Self.summarySection(sideInset: sideInset)
        }
        switch section {
        case .summary:
            return Self.summarySection(sideInset: sideInset)
        case .cast:
            if castNote != nil {
                return Self.noteSection(sideInset: sideInset)
            }
            return Self.castSection(sideInset: sideInset)
        case .similar:
            if similarNote != nil {
                return Self.noteSection(sideInset: sideInset)
            }
            return Self.similarSection(sideInset: sideInset)
        }
    }

    private func headerTitle(for sectionIndex: Int) -> String {
        switch dataSource?.sectionIdentifier(for: sectionIndex) {
        case .cast:
            return "Cast"
        case .similar:
            return "Similar"
        case .summary, .none:
            return ""
        }
    }

    private static func summarySection(sideInset: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Theme.summaryHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: sideInset, bottom: 12, trailing: sideInset)
        section.contentInsetsReference = .none
        return section
    }

    private static func castSection(sideInset: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.castCardWidth),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.castCardWidth),
            heightDimension: .absolute(Theme.castCardHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 28
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: sideInset, bottom: 28, trailing: sideInset)
        section.contentInsetsReference = .none
        section.supplementariesFollowContentInsets = true
        section.boundarySupplementaryItems = [railHeader()]
        return section
    }

    private static func similarSection(sideInset: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.relatedPosterWidth),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Theme.relatedPosterWidth),
            heightDimension: .absolute(Theme.relatedCardHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Theme.shelfSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: sideInset, bottom: 36, trailing: sideInset)
        section.contentInsetsReference = .none
        section.supplementariesFollowContentInsets = true
        section.boundarySupplementaryItems = [railHeader()]
        return section
    }

    private static func noteSection(sideInset: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: sideInset, bottom: 20, trailing: sideInset)
        section.contentInsetsReference = .none
        section.supplementariesFollowContentInsets = true
        section.boundarySupplementaryItems = [railHeader()]
        return section
    }

    private static func railHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(Theme.railHeaderHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    private func loadDetails() {
        loadTask?.cancel()
        showLoading()
        let movieID = preview.id
        loadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            async let movieResult = self.loadMovie(movieID)
            async let creditsResult = self.loadCredits(movieID)
            async let similarResult = self.loadSimilar(movieID)
            let movie = await movieResult
            let credits = await creditsResult
            let similar = await similarResult
            guard !Task.isCancelled else { return }
            switch movie {
            case .success(let movie):
                self.show(movie: movie, credits: credits, similar: similar)
            case .failure(let error):
                guard !self.isCancellation(error) else { return }
                self.showMessage(self.message(for: error), retry: true)
            }
        }
    }

    private func loadMovie(_ id: Int) async -> Result<Movie, Error> {
        do {
            return .success(try await service.movieDetails(id: id))
        } catch {
            return .failure(error)
        }
    }

    private func loadCredits(_ id: Int) async -> Result<MovieCredits, Error> {
        do {
            return .success(try await service.credits(for: id))
        } catch {
            return .failure(error)
        }
    }

    private func loadSimilar(_ id: Int) async -> Result<[Movie], Error> {
        do {
            return .success(try await service.similarMovies(to: id))
        } catch {
            return .failure(error)
        }
    }

    private func show(movie: Movie, credits: Result<MovieCredits, Error>, similar: Result<[Movie], Error>) {
        let title = movie.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            showMessage("This movie isn't available right now.", retry: true)
            return
        }

        displayedMovie = movie
        self.title = movie.title
        switch credits {
        case .success(let value):
            directorLine = value.directorLine
            castMembers = value.billedCast
            castNote = castMembers.isEmpty ? .castEmpty : nil
        case .failure:
            directorLine = nil
            castMembers = []
            castNote = .castFailed
        }
        switch similar {
        case .success(let movies):
            similarMovies = uniqueMovies(movies, excluding: movie.id)
            similarNote = similarMovies.isEmpty ? .similarEmpty : nil
        case .failure:
            similarMovies = []
            similarNote = .similarFailed
        }
        applyContent()
    }

    private func uniqueMovies(_ movies: [Movie], excluding excludedID: Int) -> [Movie] {
        var seen = Set<Int>([excludedID])
        return movies.filter { seen.insert($0.id).inserted }
    }

    private func applyContent() {
        var snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailItem>()
        snapshot.appendSections([.summary, .cast, .similar])
        snapshot.appendItems([.summary], toSection: .summary)
        if let castNote {
            snapshot.appendItems([.note(castNote)], toSection: .cast)
        } else {
            snapshot.appendItems(castMembers.map { DetailItem.person($0) }, toSection: .cast)
        }
        if let similarNote {
            snapshot.appendItems([.note(similarNote)], toSection: .similar)
        } else {
            snapshot.appendItems(similarMovies.map { DetailItem.similar($0) }, toSection: .similar)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
        collectionView.setCollectionViewLayout(makeLayout(sideInset: appliedSideInset), animated: false)

        statusContainer.isHidden = true
        spinner.stopAnimating()
        collectionView.isHidden = false
        refreshFocus()
    }

    private func showLoading() {
        collectionView.isHidden = true
        statusContainer.isHidden = false
        statusLabel.text = "Loading \(preview.title)…"
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
        refreshFocus()
    }

    private func showMessage(_ text: String, retry: Bool) {
        collectionView.isHidden = true
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
        if error is URLError {
            return "Check the network connection and try again."
        }
        return "Something went wrong while loading this movie."
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        return false
    }

    private func refreshFocus() {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func retryTapped() {
        loadDetails()
    }
}

final class DetailNoteCell: UICollectionViewCell {
    private let label = UILabel()

    override var canBecomeFocused: Bool { true }

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        label.textColor = Theme.secondaryText
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        backgroundColor = .clear
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) {
        fatalError("Notes are created in code.")
    }

    func configure(_ text: String) {
        label.text = text
        accessibilityLabel = text
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.textColor = Theme.secondaryText
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self = self else { return }
            self.label.textColor = self.isFocused ? Theme.primaryText : Theme.secondaryText
        }
    }
}
