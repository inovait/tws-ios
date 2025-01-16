# File Downloads

Manage File Downloads and Access

## Overview

If you download a file through the ``TWSView``, the file will be stored in the app's documents directory. By default, that folder is private, and you have two options available to you:

1. Make your documents public: In your `Info.plist`, ensure you've set `UIFileSharingEnabled` to `true`. If you have used our project generator, this will already be set to true.

2. Check the download completed callback: ``SwiftUICore/View/twsOnDownloadCompleted(action:)``. On a successful download, you'll receive an instance of ``TWSDownloadInfo``. This includes the full path to the downloaded file, which you can use to move the file to a location of your choosing.
