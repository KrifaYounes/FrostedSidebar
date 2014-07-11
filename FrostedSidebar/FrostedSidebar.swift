//
//  FrostedSidebar.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import QuartzCore

protocol FrostedSidebarDelegate{
    func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
    func sidebar(sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int)
}

class CalloutItem: UIView{
    var imageView:              UIImageView                 = UIImageView()
    var itemIndex:              Int
    var originalBackgroundColor:UIColor? {
    didSet{
        self.backgroundColor = originalBackgroundColor
    }
    }
    
    init(index: Int){
        imageView.backgroundColor = UIColor.clearColor()
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        itemIndex = index
        super.init(frame: CGRect.zeroRect)
        addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = bounds.size.height/2
        imageView.frame = CGRect(x: 0, y: 0, width: inset, height: inset)
        imageView.center = CGPoint(x: inset, y: inset)
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesBegan(touches, withEvent: event)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let darkenFactor: CGFloat = 0.3
        var darkerColor: UIColor
        if originalBackgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a){
            darkerColor = UIColor(red: max(r - darkenFactor, 0), green: max(g - darkenFactor, 0), blue: max(b - darkenFactor, 0), alpha: a)
        } else if originalBackgroundColor?.getWhite(&r, alpha: &a){
            darkerColor = UIColor(white: max(r - darkenFactor, 0), alpha: a)
        } else{
            darkerColor = UIColor.clearColor()
            assert(false, "Item color should be RBG of White/Alpha in order to darken the button")
        }
        backgroundColor = darkerColor
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesEnded(touches, withEvent: event)
        backgroundColor = originalBackgroundColor
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        backgroundColor = originalBackgroundColor
    }
    
    
    
}

class FrostedSidebar: UIViewController {
    
    var width:                  CGFloat                     = 145
    var showFromRight:          Bool                        = false
    var animationDuration:      CGFloat                     = 0.25
    var itemSize:               CGSize                      = CGSizeMake(90, 90)
    var tintColor:              UIColor                     = UIColor(white: 0.2, alpha: 0.73)
    var itemBackgroundColor:    UIColor                     = UIColor(white: 1, alpha: 0.25)
    var borderWidth:            CGFloat                     = 2
    var delegate:               FrostedSidebarDelegate?     = nil
    //Only one of these properties can be used at a time. If one is true, the other automatically is false
    var isSingleSelect:         Bool                        = false{
    didSet{
        if isSingleSelect{ calloutsAlwaysSelected = false }
    }
    }
    var calloutsAlwaysSelected: Bool                        = false{
    didSet{
        if calloutsAlwaysSelected{
            isSingleSelect = false
            selectedIndices = NSMutableIndexSet(indexesInRange: NSRange(location: 0,length: images.count) )
        }
    }
    }
 
    var contentView:            UIScrollView                = UIScrollView()
    var blurView:               UIVisualEffectView          = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    var dimView:                UIView                      = UIView()
    var tapGesture:             UITapGestureRecognizer?     = nil
    var images:                 [UIImage]                   = []
    var borderColors:           [UIColor]?                  = nil
    var itemViews:              [CalloutItem]               = []
    var selectedIndices:        NSMutableIndexSet           = NSMutableIndexSet()
    var actionForIndex:         [Int : ()->()]              = [:]
    
    init(itemImages: [UIImage], colors: [UIColor]?, selectedItemIndices: NSIndexSet?){
        contentView.alwaysBounceHorizontal = false
        contentView.alwaysBounceVertical = true
        contentView.bounces = true
        contentView.clipsToBounds = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        if colors{
            assert(itemImages.count == colors!.count, "If item color are supplied, the itemImages and colors arrays must be of the same size.")
        }
        
        selectedIndices = selectedItemIndices ? NSMutableIndexSet(indexSet: selectedItemIndices!) : NSMutableIndexSet()
        borderColors = colors
        images = itemImages
        
        for (index, image) in enumerate(images){
            let view = CalloutItem(index: index)
            view.clipsToBounds = true
            view.imageView.image = image
            contentView.addSubview(view)
            itemViews += view
            if borderColors{
                if selectedIndices.containsIndex(index){
                    let color = borderColors![index]
                    view.layer.borderColor = color.CGColor
                }
            } else{
                view.layer.borderColor = UIColor.clearColor().CGColor
            }
        }
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    func setActionsForIndex(index: Int, action: () -> Void){
        actionForIndex[index] = action
    }
    
    func removeActionForIndex(index: Int){
        actionForIndex.removeValueForKey(index)
    }
    
    func removeAllActions(){
        actionForIndex.removeAll(keepCapacity: false)
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.clearColor()
        view.addSubview(dimView)
        view.addSubview(blurView)
        view.addSubview(contentView)
        tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapGesture!)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.toRaw())
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        if isViewLoaded(){
            dismissAnimated(false, completion: nil)
        }
    }
    
    func animateSpringWithView(view: CalloutItem, idx: Int, initDelay: CGFloat){
        let delay: NSTimeInterval = NSTimeInterval(initDelay) + NSTimeInterval(idx) * 0.1
        UIView.animateWithDuration(0.5,
            delay: delay,
            usingSpringWithDamping: 10.0,
            initialSpringVelocity: 50.0,
            options: UIViewAnimationOptions.BeginFromCurrentState,
            animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1
            },
            completion: nil)
    }
    
    func showInViewController(viewController: UIViewController, animated: Bool){
        delegate?.sidebar(self, willShowOnScreenAnimated: animated)
        addToParentViewController(viewController, callingAppearanceMethods: true)
        view.frame = viewController.view.bounds
        
        dimView.backgroundColor = UIColor.blackColor()
        dimView.alpha = 0
        dimView.frame = view.bounds
        
        let parentWidth = view.bounds.size.width
        var contentFrame = view.bounds
        contentFrame.origin.x = showFromRight ? parentWidth : -width
        contentFrame.size.width = width
        contentView.frame = contentFrame
        contentView.contentOffset = CGPoint(x: 0, y: 0)
        layoutItems()
        
        var blurFrame = CGRect(x: showFromRight ? view.bounds.size.width : 0, y: 0, width: 0, height: view.bounds.size.height)
        blurView.frame = blurFrame
        blurView.contentMode = showFromRight ? UIViewContentMode.TopRight : UIViewContentMode.TopLeft
        blurView.clipsToBounds = true
        view.insertSubview(blurView, belowSubview: contentView)
        
        contentFrame.origin.x = showFromRight ? parentWidth - width : 0
        blurFrame.origin.x = contentFrame.origin.x
        blurFrame.size.width = width
        
        let animations: () -> () = {
            self.contentView.frame = contentFrame
            self.blurView.frame = blurFrame
            self.dimView.alpha = 0.25
        }
        let completion: (Bool) -> Void = { finished in
            if finished{
                self.delegate?.sidebar(self, didShowOnScreenAnimated: animated)
            }
        }
        
        if animated{
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.fromRaw(UInt(kNilOptions))!, animations: animations, completion: completion)
        } else{
            animations()
            completion(true)
        }
        
        for (index, item) in enumerate(itemViews){
            item.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1)
            item.alpha = 0
            item.originalBackgroundColor = itemBackgroundColor
            item.layer.borderWidth = borderWidth
            animateSpringWithView(item, idx: index, initDelay: animationDuration)
        }
        
    }
    
    func dismissAnimated(animated: Bool, completion: ((Bool) -> Void)?){
        let completionBlock: (Bool) -> Void = {finished in
            self.removeFromParentViewControllerCallingAppearanceMethods(true)
            self.delegate?.sidebar(self, didDismissFromScreenAnimated: true)
            self.layoutItems()
            if completion{
                completion!(finished)
            }
        }
        delegate?.sidebar(self, willDismissFromScreenAnimated: animated)
        if animated{
            let parentWidth = view.bounds.size.width
            var contentFrame = contentView.frame
            contentFrame.origin.x = showFromRight ? parentWidth : -width
            var blurFrame = blurView.frame
            blurFrame.origin.x = showFromRight ? parentWidth : 0
            blurFrame.size.width = 0
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.contentView.frame = contentFrame
                self.blurView.frame = blurFrame
                self.dimView.alpha = 0
                }, completion: completionBlock)
        } else{
            completionBlock(true)
        }
    }
    
    func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.locationInView(view)
        if !CGRectContainsPoint(contentView.frame, location){
            dismissAnimated(true, completion: nil)
        } else{
            let tapIndex = indexOfTap(recognizer.locationInView(contentView))
            if tapIndex{
                didTapItemAtIndex(tapIndex!)
            }
        }
    }
    
    func didTapItemAtIndex(index: Int){
        let didEnable = !selectedIndices.containsIndex(index)
        if borderColors{
            let stroke = borderColors![index]
            let item = itemViews[index]
            if didEnable{
                if isSingleSelect{
                    selectedIndices.removeAllIndexes()
                    for (index, item) in enumerate(itemViews){
                        item.layer.borderColor = UIColor.clearColor().CGColor
                    }
                }
                item.layer.borderColor = stroke.CGColor
                
                var borderAnimation = CABasicAnimation(keyPath: "borderColor")
                borderAnimation.fromValue = UIColor.clearColor().CGColor
                borderAnimation.toValue = stroke.CGColor
                borderAnimation.duration = 0.5
                item.layer.addAnimation(borderAnimation, forKey: nil)
                selectedIndices.addIndex(index)
				
            } else{
                if !isSingleSelect{
                    if !calloutsAlwaysSelected{
                        item.layer.borderColor = UIColor.clearColor().CGColor
                        selectedIndices.removeIndex(index)
                    }
                }
            }
            let pathFrame = CGRect(x: -CGRectGetMidX(item.bounds), y: -CGRectGetMidY(item.bounds), width: item.bounds.size.width, height: item.bounds.size.height)
            let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: item.layer.cornerRadius)
            let shapePosition = view.convertPoint(item.center, fromView: contentView)
            let circleShape = CAShapeLayer()
            circleShape.path = path.CGPath
            circleShape.position = shapePosition
            circleShape.fillColor = UIColor.clearColor().CGColor
            circleShape.opacity = 0
            circleShape.strokeColor = stroke.CGColor
            circleShape.lineWidth = borderWidth
            view.layer.addSublayer(circleShape)
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
            scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(2.5, 2.5, 1))
            let alphaAnimation = CABasicAnimation(keyPath: "opacity")
            alphaAnimation.fromValue = 1
            alphaAnimation.toValue = 0
            let animation = CAAnimationGroup()
            animation.animations = [scaleAnimation, alphaAnimation]
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            circleShape.addAnimation(animation, forKey: nil)
        }
        if let action = actionForIndex[index]{
            action()
        }
        delegate?.sidebar(self, didTapItemAtIndex: index)
        delegate?.sidebar(self, didEnable: didEnable, itemAtIndex: index)
    }
    
    func layoutSubviews(){
        let x = showFromRight ? parentViewController.view.bounds.size.width - width : 0
        contentView.frame = CGRect(x: x, y: 0, width: width, height: parentViewController.view.bounds.size.height)
        blurView.frame = contentView.frame
        layoutItems()
    }
    
    func layoutItems(){
        let leftPadding = (width - itemSize.width) / 2
        let topPadding = leftPadding
        for (index, item) in enumerate(itemViews){
            let idx: CGFloat = CGFloat(index)
            let frame = CGRect(x: leftPadding, y: topPadding*idx + itemSize.height*idx + topPadding, width:itemSize.width, height: itemSize.height)
            item.frame = frame
            item.layer.cornerRadius = frame.size.width / 2
			item.layer.borderColor = UIColor.clearColor().CGColor
			item.alpha = 0
			if selectedIndices.containsIndex(index){
				if borderColors{
					item.layer.borderColor = borderColors![index].CGColor
				}
			}
        }
        let itemCount = CGFloat(itemViews.count)
        contentView.contentSize = CGSizeMake(0, itemCount * (itemSize.height + topPadding) + topPadding)
    }
    
    func indexOfTap(location: CGPoint) -> Int? {
        var index: Int?
        for (idx, item) in enumerate(itemViews){
            if CGRectContainsPoint(item.frame, location){
                index = idx
                break
            }
        }
        return index
    }
    
    func addToParentViewController(viewController: UIViewController, callingAppearanceMethods: Bool){
        if parentViewController{
            removeFromParentViewControllerCallingAppearanceMethods(callingAppearanceMethods)
        }
        if callingAppearanceMethods{
            beginAppearanceTransition(true, animated: false)
        }
        viewController.addChildViewController(self)
        viewController.view.addSubview(self.view)
        didMoveToParentViewController(self)
        if callingAppearanceMethods{
            endAppearanceTransition()
        }
    }
    
    func removeFromParentViewControllerCallingAppearanceMethods(callAppearanceMethods: Bool){
	
		if callAppearanceMethods{
            beginAppearanceTransition(false, animated: false)
        }
        willMoveToParentViewController(nil)
        view.removeFromSuperview()
        removeFromParentViewController()
        if callAppearanceMethods{
            endAppearanceTransition()
        }
    }
}