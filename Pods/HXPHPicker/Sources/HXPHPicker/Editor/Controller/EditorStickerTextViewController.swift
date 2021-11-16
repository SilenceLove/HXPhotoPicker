//
//  EditorStickerTextViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

protocol EditorStickerTextViewControllerDelegate: AnyObject {
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerText: EditorStickerText
    )
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerItem: EditorStickerItem
    )
}

class EditorStickerTextController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

final class EditorStickerTextViewController: BaseViewController {
    weak var delegate: EditorStickerTextViewControllerDelegate?
    private let config: EditorTextConfiguration
    private let stickerItem: EditorStickerItem?
    init(config: EditorTextConfiguration,
         stickerItem: EditorStickerItem? = nil) {
        self.config = config
        self.stickerItem = stickerItem
        super.init(nibName: nil, bundle: nil)
    }
    
    lazy var bgView: UIVisualEffectView = {
        let effext = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView.init(effect: effext)
        return view
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.size = CGSize(width: 60, height: 30)
        button.addTarget(self, action: #selector(didCancelButtonClick), for: .touchUpInside)
        return button
    }()
    
    @objc func didCancelButtonClick() {
        dismiss(animated: true, completion: nil)
    }
    
    lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        let text = "完成".localized
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        var textWidth = text.width(ofFont: .systemFont(ofSize: 17), maxHeight: 30)
        if textWidth < 60 {
            textWidth = 60
        }else {
            textWidth += 10
        }
        button.size = CGSize(width: textWidth, height: 30)
        button.setBackgroundImage(
            UIImage.image(
                for: config.tintColor,
                havingSize: button.size,
                radius: 3
            ),
            for: .normal
        )
        button.addTarget(
            self,
            action: #selector(didFinishButtonClick),
            for: .touchUpInside
        )
        return button
    }()
    
    @objc func didFinishButtonClick() {
        if let image = textView.textImage(), !textView.text.isEmpty {
            let stickerText = EditorStickerText(
                image: image,
                text: textView.text,
                textColor: textView.currentSelectedColor,
                showBackgroud: textView.showBackgroudColor
            )
            if stickerItem != nil {
                let stickerItem = EditorStickerItem(image: image, imageData: nil, text: stickerText)
                delegate?.stickerTextViewController(self, didFinish: stickerItem)
            }else {
                delegate?.stickerTextViewController(self, didFinish: stickerText)
            }
        }
        textView.textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    lazy var textView: EditorStickerTextView = {
        let view = EditorStickerTextView(config: config, stickerText: stickerItem?.text)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let nav = navigationController,
           nav.modalPresentationStyle == .fullScreen {
            view.backgroundColor = "#666666".color
        }else {
            view.backgroundColor = .clear
        }
        navigationController?.view.backgroundColor = .clear
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: finishButton)
        view.addSubview(bgView)
        view.addSubview(textView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage.image(
            for: UIColor.clear,
            havingSize: .zero
        )
        navigationController?.navigationBar.setBackgroundImage(
            UIImage.image(
                for: UIColor.clear,
                havingSize: .zero
            ),
            for: .default
        )
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.frame = view.bounds
        textView.x = 0
        textView.y = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        textView.width = view.width
        textView.height = view.height - textView.y
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
