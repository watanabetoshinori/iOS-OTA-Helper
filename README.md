# iOS OTA Helper

iOS OTA Helper is MacOS X app designed to simplify sharing iOS apps via Over the Air.

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Features

- [x] Simplify Shareing Enterprise/AdHoc/Development release of iOS apps.
- [x] Sharing started by simply drag & drop ipa file.
- [x] Display QR code that can access URL from iOS device.

### Preview

<img  src="https://raw.githubusercontent.com/watanabetoshinori/iOS-OTA-Helper/master/Preview/1.png" width="223" height="332"> <img  src="https://raw.githubusercontent.com/watanabetoshinori/iOS-OTA-Helper/master/Preview/2.png" width="223" height="332">

## Requirements

- macOS 10.13+
- Xcode 9.0+
- Swift 4.0+

- Python (macOS system default)
- ngrok ([https://ngrok.com](https://ngrok.com))

## Installation

This app required [ngrok](https://ngrok.com). You can install it by [homebrew](https://brew.sh):

```bash
$ brew cask install ngrok
```

## Usage

1. Lunch the iOS OTA Helper.

2. Drag & Drop your ipa file.

3. Scan QR code by iOS device and install the app!

## License

iOS OTA Helper is released under the MIT license. [See LICENSE](https://github.com/watanabetoshinori/iOS-OTA-Helper/blob/master/LICENSE) for details.

# Acknowledgements

Some function of this app is based on the following app. Thank you for a great code:

- [iOS Beta Builder](https://github.com/HunterHillegas/iOS-BetaBuilder)
