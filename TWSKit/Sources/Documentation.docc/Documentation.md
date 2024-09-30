# ``TWSKit``

SDK for creating custom mobile apps


## Overview

This documentation will guide you through implementing TWSKit into your own app

![The WebSnippet Logo](appIcon-200x200)

### Quick tutorial

- [Getting started](<doc:Tutorial-Table-of-Contents>)

### Setting up the project with CLI

- [iOS Project Generator CLI](https://github.com/inovait/tws-cli/tree/main/ios)

### How to handle Google Login

- [Handling Google Login](<doc:GoogleLogin>)

### Downloading files

If you download a file through the ``TWSView``, the file will be stored in the app's documents directory. By default that folder is private and you have 2 options available to you:

**1 - Make your documents public:** In your info.plist make sure you've set the "UIFileSharingEnabled" to true. If you have used our project generator it will be already set to true.

**2 - Check the download completed callback:** On a successful download you'll receive an instance of ``TWSDownloadInfo``. This will include the full path to the downloaded file and you can use this URL to move the file to the location of your choosing.
