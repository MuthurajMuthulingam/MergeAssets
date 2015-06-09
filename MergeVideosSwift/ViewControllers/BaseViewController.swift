//
//  BaseViewController.swift
//  MergeVideosSwift
//
//  Created by Muthuraj M on 6/6/15.
//  Copyright (c) 2015 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public class BaseViewController: UIViewController {

    var hud:MBProgressHUD?;
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        hud = MBProgressHUD(view:self.view);
        
        if(hud != nil)
        {
            self.view.addSubview(hud!);
        }
        
        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   // Mark: show Alert View
    
    public func showAlert(message:String) {
        var alertView:UIAlertView = UIAlertView(title: "MergeVideosSwift", message: message, delegate: nil, cancelButtonTitle: "OK")
        alertView.show()
    }
    
    // Mark: show Progress Loading 
    
    public func showLoading(message:String) {
        
        if(hud != nil) {
            hud!.mode = MBProgressHUDMode.Indeterminate;
            hud!.labelText = message
            hud!.show(true);
        }
    }
    
    // Mark: hide Progress Loading
    
    public func hideLoading() {
        hud!.hide(true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
