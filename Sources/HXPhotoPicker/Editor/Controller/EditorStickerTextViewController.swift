//
//  EditorStickerTextViewController.swift
//  HXPhotoPicker
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
        didFinishUpdate stickerText: EditorStickerText
    )
}

class EditorStickerTextController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

final class EditorStickerTextViewController: HXBaseViewController {
    weak var delegate: EditorStickerTextViewControllerDelegate?
    private let config: EditorConfiguration.Text
    private let stickerText: EditorStickerText?
    init(config: EditorConfiguration.Text,
         stickerText: EditorStickerText? = nil) {
        self.config = config
        self.stickerText = stickerText
        super.init(nibName: nil, bundle: nil)
    }
    
    private var bgView: UIVisualEffectView!
    private var cancelButton: UIButton!
    private var finishButton: UIButton!
    private var textView: EditorStickerTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let nav = navigationController,
           nav.modalPresentationStyle == .fullScreen {
            view.backgroundColor = "#666666".color
        }else {
            view.backgroundColor = .clear
        }
        initViews()
        navigationController?.view.backgroundColor = .clear
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: finishButton)
        view.addSubview(bgView)
        view.addSubview(textView)
    }
    
    private func initViews() {
        let effext = UIBlurEffect(style: .dark)
        bgView = UIVisualEffectView.init(effect: effext)
        
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle(.textManager.editor.text.cancelTitle.text, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .textManager.editor.text.cancelTitleFont
        cancelButton.size = CGSize(width: 60, height: 30)
        cancelButton.addTarget(self, action: #selector(didCancelButtonClick), for: .touchUpInside)
        
        finishButton = UIButton(type: .system)
        let text: String = .textManager.editor.text.finishTitle.text
        let finishFont: UIFont = .textManager.editor.text.finishTitleFont
        finishButton.setTitle(text, for: .normal)
        finishButton.setTitleColor(config.doneTitleColor, for: .normal)
        finishButton.titleLabel?.font = finishFont
        var textWidth = text.width(ofFont: finishFont, maxHeight: 30)
        if textWidth < 60 {
            textWidth = 60
        }else {
            textWidth += 10
        }
        finishButton.size = CGSize(width: textWidth, height: 30)
        if config.doneBackgroundColor != UIColor.clear {
            finishButton.setBackgroundImage(
                UIImage.image(
                    for: config.doneBackgroundColor,
                    havingSize: finishButton.size,
                    radius: 3
                ),
                for: .normal
            )
        }
        finishButton.addTarget(
            self,
            action: #selector(didFinishButtonClick),
            for: .touchUpInside
        )
        
        textView = EditorStickerTextView(config: config, stickerText: stickerText)
    }
    
    @objc
    private func didCancelButtonClick() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func didFinishButtonClick() {
        if let image = textView.textImage(), !textView.text.isEmpty {
            let stickerText = EditorStickerText(
                image: image,
                text: textView.text,
                textColor: textView.currentSelectedColor,
                showBackgroud: textView.showBackgroudColor
            )
            if self.stickerText != nil {
                delegate?.stickerTextViewController(self, didFinishUpdate: stickerText)
            }else {
                delegate?.stickerTextViewController(self, didFinish: stickerText)
            }
        }
        textView.textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
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
