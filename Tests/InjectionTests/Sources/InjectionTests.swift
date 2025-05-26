////
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Testing
import TWSCommon

@Suite("Resource injection Tests")
struct InjectionTests {

    @Test("Inject css/javascript in to head tag", arguments: [(
            """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Example Page</title>
            </head>
            <body>
              <h1>Welcome to My Page</h1>
              <p>This is a basic example of an HTML document structure with a head and body.</p>
            </body>
            </html>
            """,
          "body { background-color: red; }",
          "alert('Hello, world!');")]
    )
    func injectToHead(html: String, css: String, javascript: String) async throws {
        let expectedResult =
"""
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Example Page</title>
<style>body { background-color: red; }</style><script>alert('Hello, world!');</script></head>
<body>
  <h1>Welcome to My Page</h1>
  <p>This is a basic example of an HTML document structure with a head and body.</p>
</body>
</html>
"""
        var resultingHtml = html
        
        injectCSS(for: &resultingHtml, css: css)
        injectJavaScript(for: &resultingHtml, javascript: javascript)
        assert(expectedResult == resultingHtml)
    }
    
    @Test("Inject css/javascript in to HTML tag", arguments: [(
            """
            <!DOCTYPE html>
            <html lang="en">
            <body>
              <h1>Welcome to My Page</h1>
              <p>This is a basic example of an HTML document structure with a head and body.</p>
            </body>
            </html>
            """,
          "body { background-color: red; }",
          "alert('Hello, world!');")])
    func injectToHTML(html: String, css: String, javascript: String) async throws {
        let expectedResult =
"""
<!DOCTYPE html>
<html lang="en"><script>alert('Hello, world!');</script><style>body { background-color: red; }</style>
<body>
  <h1>Welcome to My Page</h1>
  <p>This is a basic example of an HTML document structure with a head and body.</p>
</body>
</html>
"""
        var resultingHtml = html
        
        injectCSS(for: &resultingHtml, css: css)
        injectJavaScript(for: &resultingHtml, javascript: javascript)
        assert(expectedResult == resultingHtml)
    }
    
    @Test("Inject css/javascript at end of file", arguments: [(
            """
            <!DOCTYPE html>
            <body>
              <h1>Welcome to My Page</h1>
              <p>This is a basic example of an HTML document structure with a head and body.</p>
            </body>
            """,
          "body { background-color: red; }",
          "alert('Hello, world!');")])
    func injectToEndOfFile(html: String, css: String, javascript: String) async throws {
        let expectedResult =
"""
<script>alert('Hello, world!');</script><!DOCTYPE html>
<body>
  <h1>Welcome to My Page</h1>
  <p>This is a basic example of an HTML document structure with a head and body.</p>
</body><style>body { background-color: red; }</style>
"""
        var resultingHtml = html
        
        injectCSS(for: &resultingHtml, css: css)
        injectJavaScript(for: &resultingHtml, javascript: javascript)
        assert(expectedResult == resultingHtml)
    }

}
