# Handling Google Login

A guide to integrating Google Login with your snippets.

## Overview 

Google enforces strict security measures for their login functionality, which prevents completing the login process directly within a snippet. To make this functionality work, you’ll need to handle the login in your phone’s browser and manage the response.

This guide walks you through the process.

## Setup universal links

You’ll need to configure Universal Links for your app on the domain used for Google Login. Ensure the URL that Google Login calls after authentication matches your app's configuration. In this example, the path `/__/auth/handler` is used. If you are building the project using the CLI, this same path must be specified during setup. Additional details about CLI configuration can be found on the main page under the dedicated CLI link.

Your `apple-app-site-association` file should look like this:

```json
{
    "applinks": {
        "details": [
            {
                "appID": <Insert your bundle ID>,
                "paths": [
                    "/__/auth/handler"
                ]
            }
        ]
    }
}
```

For more details on Universal Links, refer to Apple’s documentation: [Supporting Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)

## Handle incoming URL



The ``TWSView`` you're using will now automatically handle the redirects from the phone's browser.
