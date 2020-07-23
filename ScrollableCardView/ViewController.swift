//
//  ViewController.swift
//  ScrollableCardView
//
//  Created by 劉峻岫 on 2020/7/23.
//  Copyright © 2020 addcn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func didTapButton(_ sender: UIButton) {
        let vc = ScrollableViewController(
            popViewHeight: 600,
            popupOffset: 0,
            childViewController: ViewController()
        )
        vc.titleLabel.text = "Test"
        vc.modalPresentationStyle = .overFullScreen
        vc.canDrag = true
        show(vc, sender: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

