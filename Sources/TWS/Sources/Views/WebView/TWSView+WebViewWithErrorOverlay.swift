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

import Foundation
import UIKit
import WebKit

class WebViewWithErrorOverlay: UIView {
    // MARK: - Properties
    let webView: WKWebView
    private let errorOverlay: UILabel
    private let closeButton: UIButton
    
    init(webView: WKWebView) {
        self.webView = webView
        self.errorOverlay = {
            let label = UILabel()
            label.text = "Something went wrong"
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.isHidden = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        self.closeButton = {
            let closeButton = UIButton(type: .system)
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = .black
            closeButton.isHidden = true
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            return closeButton
        }()
        super.init(frame: .zero)
        setupSubviews()
    }

    // MARK: - Init


    required init?(coder: NSCoder) {
        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        self.errorOverlay = UILabel()
        self.closeButton = UIButton(type: .system)
        super.init(coder: coder)
        setupSubviews()
    }

    // MARK: - Setup

    private func setupSubviews() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        addSubview(errorOverlay)
        addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),

            errorOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorOverlay.topAnchor.constraint(equalTo: topAnchor),
            errorOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ])
    }
    
    @objc private func closeTapped() {
        hideError()
    }

    // MARK: - Public API

    func showError(message: String?) {
        errorOverlay.text = message ?? "Something went wrong"
        errorOverlay.isHidden = false
        closeButton.isHidden = false
    }

    func hideError() {
        errorOverlay.isHidden = true
        closeButton.isHidden = true
    }
}
