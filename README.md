# Apple TV Popular Movies

A dark tvOS shelf for movies on [TMDb](https://www.themoviedb.org/). The catalog is a set of horizontal rails. Focus a poster to read the year, rating, and a short overview. Open it for the director, the cast, and similar titles.

The catalog and the detail page are what you see in the tvOS simulator after you put your own TMDb key in `Info.plist`.

## Technologies

| | |
| --- | --- |
| Platform | tvOS 18 |
| UI | UIKit, built in code. No storyboards |
| Layout | `UICollectionView` compositional layout, one shelf per section |
| Focus | tvOS focus engine, scale and a focus ring |
| Networking | `async`/`await` `URLSession` |
| Models | `Decodable` |
| Images | TMDb image CDN, decoded off the main thread |
| Data | TMDb API v3 |

TMDb endpoints:

- `/movie/popular`
- `/movie/top_rated`
- `/movie/now_playing`
- `/movie/upcoming`
- `/movie/{id}`
- `/movie/{id}/credits`
- `/movie/{id}/similar`
- Poster and profile images from the TMDb image base URL

There are no third-party packages.

## Add your key

This repository does not ship a TMDb key. `TMDBAPIKey` in `AppleTVMovieApp/Info.plist` is an empty placeholder. Paste your own v3 key there before you run the app. Create one at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).

If the value is still empty, the catalog asks you to add it. Do not commit your key.

## What you get

- Four rails: Popular, Top Rated, Now Playing, and Upcoming. Each shelf scrolls sideways. Moving vertically switches rails.
- A backdrop behind the focused title, with year and rating chips
- Focus that scales the poster and draws a ring
- A detail page with the poster, title, year, rating, and overview
- The director, and a cast row with names and profile photos when TMDb sends them
- A similar-movies shelf. Selecting a poster opens that movie
- **Movies**, or the remote Menu button, returns to the previous screen
- Loading, empty, and error panels, with **Try Again**

## Run

You need macOS, Xcode 16 or later, and the tvOS 18 SDK. The Apple TV simulator is enough.

1. Clone the repository and open `AppleTVMovieApp.xcodeproj`.
2. Paste your TMDb key into `TMDBAPIKey`.
3. Select the **AppleTVMovieApp** scheme and an Apple TV destination.
4. If signing fails, choose your Development Team. Signing is automatic.

In the simulator, the arrow keys move and Return opens the focused title. On a remote, swipe and press. Menu goes back.

## How it is built

`SceneDelegate` owns a navigation stack with a hidden bar. `ViewController` loads the four lists together and lays them out as orthogonal shelves. Selecting a poster pushes `MovieDetailViewController`, which loads the movie, its credits, and similar titles in parallel. `ImageLoader` caches posters, backdrops, and profile photos. The deployment target is tvOS 18. Traffic is HTTPS only.

```text
AppleTVMovieApp/
  AppDelegate.swift                 entry
  SceneDelegate.swift               window and navigation
  ViewController.swift              rails, hero, catalog states
  MovieDetailViewController.swift   detail, cast, similar, detail states
  MovieCell.swift                   poster card and focus ring
  CastMemberCell.swift              cast photo, name, and role
  MovieInfoCell.swift               poster, chips, overview, director
  RailHeaderView.swift              shelf title
  MetadataChip.swift                year and rating chips
  StatusPanel.swift                 loading, empty, and error
  Movie.swift                       movie, credits, and image URLs
  MovieService.swift                TMDb lists, detail, credits, similar
  ImageLoader.swift                 image cache, decode off the main thread
  Theme.swift                       color, type, and metrics
  Info.plist                        your API key, scenes, launch color
  Assets.xcassets                   icon, top shelf, backdrop
```

## License

MIT License

Copyright (c) 2022 Halil OZEL

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Movie data and posters come from TMDb. This product uses the TMDb API but is not endorsed or certified by TMDb.
