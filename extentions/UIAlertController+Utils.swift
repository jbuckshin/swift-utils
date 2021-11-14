//
//  UIAlertController+Utils.swift
//  Blend
//
//  Created by Joe Buckshin on 5/4/20.
//  Copyright © 2020 Joseph Buckshin. All rights reserved.
//
import UIKit

extension UIAlertController {

    class func showAlert(title: String, message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true, completion: nil)
    }
}
