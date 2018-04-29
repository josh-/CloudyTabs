# CloudyTabs

CloudyTabs is a simple menu bar application that lists your iCloud Tabs and Reading List.

![CloudyTabs](http://joshparnham.com/projects/cloudytabs/CloudyTabs.png)

## Installation

* [Download CloudyTabs](https://github.com/josh-/CloudyTabs/releases/latest) and copy it to your Applications folder.

> (Alternatively, CloudyTabs is installable from your shell through [Homebrew](http://brew.sh) – once you've [set up Homebrew-cask](https://github.com/phinze/homebrew-cask/blob/master/USAGE.md#getting-started)) you can simply type `brew cask install cloudytabs`)

## Usage

To use CloudyTabs, open the app and select a tab from one of your devices. The tab's URL then opens it in your default browser (useful if like me, you use Safari on iOS and Chrome on macOS), Cmd(`⌘`)-Selecting a tab (or highlighting it and pressing Cmd(`⌘`)-Return(`⏎`)) opens the tab in the background. Opt(`⌥`)-Selecting a tab (or highlighting it and pressing Opt(`⌥`)-Return(`⏎`)) will copy the tab's URL.

Typing the first few letters or a tab's title will jump to that particular tab.

Hovering over the CloudyTabs menu bar icon displays a tooltip which lists the date that iCloud last updated the synced tabs `plist` (where CloudyTabs reads data from).

## Requirements

* OS X 10.8.2 or later
* An active iCloud account

## License

The MIT License (MIT)

Copyright (c) 2018 Josh Parnham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
