//
//  MenuTransitionManager.swift
//  SlideMenu
//
//  Created by kromah on 7/22/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import Foundation
@objc protocol MenuTransitionManagerDelegate{
    func dismiss()
}
class MenuTransitionManager: NSObject, UIViewControllerAnimatedTransitioning,UIViewControllerTransitioningDelegate {
    
    
    let duration = 0.5
    var isPresenting = false
    
    var snapShot:UIView? {
        didSet {
            if let delegate = delegate {
            
                let tapGestureRecognizer = UITapGestureRecognizer(target: delegate, action: #selector(MenuTransitionManagerDelegate.dismiss))
                snapShot?.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }
    
    var delegate:MenuTransitionManagerDelegate?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
    
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
    
    
    
        let container = transitionContext.containerView
        
        
        let moveDown = CGAffineTransform(translationX: 0, y: container.frame.height - 400)
        
        
        let moveUp = CGAffineTransform(translationX: 0, y: -50)
        
        if isPresenting{
            toView.transform = moveUp
            snapShot = fromView.snapshotView(afterScreenUpdates: true)
            container.addSubview(toView)
            container.addSubview(snapShot!)
        }
        
        
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
            
            if self.isPresenting {
                self.snapShot?.transform = moveDown
                toView.transform = CGAffineTransform.identity
            } else {
                self.snapShot?.transform = CGAffineTransform.identity
                fromView.transform = moveUp
            }
            
            }, completion: {finished in
                
                transitionContext.completeTransition(true)
                
                if !self.isPresenting {
                    self.snapShot?.removeFromSuperview()
                }
        })
        
    }
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
    
    
}
