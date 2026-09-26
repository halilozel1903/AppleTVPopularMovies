# Apple TV Popular Movies

A dark tvOS shelf for what is popular on [TMDb](https://www.themoviedb.org/) tonight. Focus a poster to read the year, rating, and a short overview. Select it for the full page.

![Catalog](Screenshots/catalog.png)

![Detail](Screenshots/detail.png)

## Add your key first

This repository does not include a TMDb key. The app will not load movies until you paste your own.

1. Create a v3 API key at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).
2. Open `AppleTVMovieApp/Info.plist`.
3. Paste the key into the empty `TMDBAPIKey` string.
4. Run. If that value is still empty, the shelf tells you to add it.

Do not commit your key.

## What you get

- A horizontal poster shelf of the current popular list
- Focus that scales the card and updates the title, year, rating, and overview
- A detail page with the large poster and the full synopsis
- **Movies**, or the menu button, back to the shelf
- Loading, empty, and error states, with **Try Again**
- Posters fetched off the main thread and cached in memory
- UIKit only. No third-party packages

## Run

You need macOS, Xcode 16 or later, and the tvOS 18 SDK. An Apple TV simulator is enough.

1. Clone the repository and open `AppleTVMovieApp.xcodeproj`.
2. Paste your TMDb key into `TMDBAPIKey`, as above.
3. Select the **AppleTVMovieApp** scheme and an Apple TV destination.
4. If signing fails, choose your Development Team. Signing is automatic.

In the simulator, the arrow keys move and Return opens the focused title. On a remote, swipe and press. Menu returns to the shelf.

## How it is built

`SceneDelegate` owns a navigation stack with a hidden bar. `ViewController` requests `GET /3/movie/popular`. Selecting a poster pushes `MovieDetailViewController`, which requests `GET /3/movie/{id}`. Both responses decode into `Movie`. `ImageLoader` downloads `w780` posters. The deployment target is tvOS 18. Traffic is HTTPS only.

```text
AppleTVMovieApp/
  AppDelegate.swift                 entry
  SceneDelegate.swift               window and navigation
  ViewController.swift              shelf and catalog states
  MovieDetailViewController.swift   detail page
  MovieCell.swift                   poster card
  Movie.swift                       decoded movie
  MovieService.swift                popular list and one title
  ImageLoader.swift                 poster cache
  Theme.swift                       color and type scale
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
