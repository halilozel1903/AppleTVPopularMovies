//
//  ViewController.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    private let service = MovieService()
    private var loadTask: Task<Void, Never>?
    private var movies = [Movie]()
    
    var defaultSize = CGSize(width: 325,height: 489)
    var focusSize = CGSize(width: 360,height: 520)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        loadMovies()
    }

    private func loadMovies() {
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let results = try await self.service.popularMovies()
                guard !Task.isCancelled else { return }
                self.movies = self.uniqueMovies(results)
                self.collectionView.reloadData()
            } catch is CancellationError {
                return
            } catch let error as URLError where error.code == .cancelled {
                return
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func uniqueMovies(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        return movies.filter { seen.insert($0.id).inserted }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // icerikleri alma islemleri
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MovieCell{
            
            let movie = movies[indexPath.row]
            cell.configureCell(movie: movie)
            
            return cell
        }else{
            return MovieCell()
        }
        
    }
    
    // cekilen icerik kadar collection olacak
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // collectionview kaplanacak alan
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 386, height: 610)
    }
    
    // fokus olaylarinin ele alindigi fonksiyon
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        // onceki
        if let  prev = context.previouslyFocusedView as? MovieCell{
            UIView.animate(withDuration: 0.1) {
                prev.movieImage.frame.size = self.defaultSize
            }
        }
        
        // sonraki
        if let  next = context.nextFocusedView as? MovieCell{
            UIView.animate(withDuration: 0.1) {
                next.movieImage.frame.size = self.focusSize
            }
        }
    }


}

