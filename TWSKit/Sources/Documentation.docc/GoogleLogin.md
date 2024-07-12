# Handling Google Login

A quick guide to handling Google Login in your snippets

Google has implemented security around their login functionality. As such, you are unable to successfully complete the login process within the snippet. This means that in order to get the functionality to work, you'll need to handle the login in your phone's browser and then handle the response.

This guide will show you how

### Setup universal links

You'll need to setup UniversalLinks for your app on the domain you're trying to login with Google. Your assetlinks.json should look like this:

```
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

You can read more about UniversalLinks in Apple's documentation: [Universal Links](https://developer.apple.com/documentation/xcode/supporting-associated-domains)

### Handle incoming URL

The ``TWSView`` you're using will now automatically handle the redirects from the phone's browser.
