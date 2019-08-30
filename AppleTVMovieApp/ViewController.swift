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
    
    // base url
    let URL_BASE = "https://api.themoviedb.org/3/movie/popular?api_key=45dfdbd49fa1f1da1f5b75fd60217433"

    // movies nesnesi
    var movies = [Movie]()
    
    var defaultSize = CGSize(width: 325,height: 489)
    var focusSize = CGSize(width: 360,height: 520)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // verileri getirme fonksiyonu
        downloadData()
    }
    
    func downloadData()  {
        let url = NSURL(string: URL_BASE)!
        let request = NSURLRequest(url: url as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest){
            (data,response,error)->
            Void in
            
            if error != nil{
                print(error.debugDescription)
            }else{
                do{
                    let dictionary = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! Dictionary<String,AnyObject>
                    
                    if let results = dictionary["results"] as? [Dictionary<String,AnyObject>]{
                       // print(results)
                        
                        for object in results{
                            
                            let movie = Movie(movieDictionary: object)
                            self.movies.append(movie)
                        }
                        
                        // gelen verileri main thread ile islem yap
                        DispatchQueue.main.async {
                        self.collectionView.reloadData()
                                    
                        }
                        
                        
                        
                    
                    }
                }catch{
                    
                }
                
            }
            
        }
        
        task.resume()
        
        
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

