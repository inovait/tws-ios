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

class WebViewWithErrorOverlay: UIViewController {
    let webView: WKWebView
    private var errorOverlay: UIView
    private var warningImage: UIImageView
    private var errorMessage: UILabel
    private var closeButton: UIButton
    private var reloadButton: UIButton

    // MARK: - Init
    init(webView: WKWebView) {
        self.webView = webView
        self.errorOverlay = {
            let errorOverlay = UIView()
            errorOverlay.backgroundColor = UIColor.white
            errorOverlay.translatesAutoresizingMaskIntoConstraints = false
            errorOverlay.isHidden = true
            return errorOverlay
        }()
        
        self.warningImage = {
            let image = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill") ?? UIImage())
            image.tintColor = .black
            image.frame.size = CGSize(width: 50, height: 50)
            image.translatesAutoresizingMaskIntoConstraints = false
            return image
        }()
        
        self.errorMessage = {
            let label = UILabel()
            label.text = "Something went wrong"
            label.textColor = .black
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        self.closeButton = {
            let closeButton = UIButton(type: .system)
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = .black
            
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            return closeButton
        }()
        self.reloadButton = {
            let reloadButton = UIButton(type: .system)
            reloadButton.setTitle("Reload", for: .normal)
            reloadButton.translatesAutoresizingMaskIntoConstraints = false
            return reloadButton
        }()
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        self.errorOverlay = UIView(frame: .zero)
        self.closeButton = UIButton(type: .system)
        self.reloadButton = UIButton(type: .system)
        self.errorMessage = UILabel()
        self.warningImage = UIImageView()
        super.init(coder: coder)
    }

    // MARK: - Setup

    override func viewDidLoad() {
        setupSubviews()
    }
    
    private func setupSubviews() {
        let stackView = UIStackView(arrangedSubviews: [warningImage, errorMessage])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addSubview(errorOverlay)
        errorOverlay.addSubview(stackView)
        errorOverlay.addSubview(closeButton)
        errorOverlay.addSubview(reloadButton)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        reloadButton.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            errorOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            errorOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            warningImage.widthAnchor.constraint(equalToConstant: 50),
            warningImage.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reloadButton.centerYAnchor.constraint(equalTo: errorMessage.bottomAnchor, constant: 20)
            
        ])
    }
    
    @objc private func closeTapped() {
        hideError()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func reloadPage() {
        webView.reload()
        hideError()
    }

    // MARK: - Public API

    func showError(message: String?) {
        errorMessage.text = message ?? "Something went wrong"
        errorOverlay.isHidden = false
        if let url = webView.url {
            reloadButton.isHidden = false
        } else {
            reloadButton.isHidden = true
        }
    }

    func hideError() {
        errorOverlay.isHidden = true
        reloadButton.isHidden = true
    }
}
