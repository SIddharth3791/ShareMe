//
//  PostViewController.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/7/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import Foundation

class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    
    var activityIndicator = UIActivityIndicatorView()
    
    let S3BucketName = "shareme-ios-project" //this needs to be moved to a settings file
    
    @IBOutlet var imagePost: UIImageView!
    
    @IBOutlet var setMessage: UITextField!
    
    @IBAction func chooseAnImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        
        self.present(image, animated: true, completion: nil)
    }

func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [AnyHashable: Any]) {
        let chosenImage: UIImage? = info[UIImagePickerControllerOriginalImage] as! UIImage?
        imagePost.image = chosenImage
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    @IBAction func postAnImage(_ sender: Any) {
        
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let S3UploadKeyName = NSUUID().uuidString + ".png"
        var location = ""
        
        if let data = UIImagePNGRepresentation(self.imagePost.image!) {
            location = databaseService.getDocumentsDirectory().appendingPathComponent(S3UploadKeyName)
            do {
                try data.write(to: URL(fileURLWithPath: location), options: .atomic)
            } catch {
                print(error)
            }
        } else {
            self.displayAlert(title: "Error", message: "Could not process selected image. UIImagePNGRepresentation failed.")
            return
        }
        
        let uploadFileUrl = NSURL.fileURL(withPath: location)
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
            print("Progress is: %f", progress.fractionCompleted)
        }
        
        let completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                if error != nil {
                    print(error)
                    self.displayAlert(title: "Could not post image", message: "Please try again later")
                } else {
                    self.savePostToDatabase(bucket: self.S3BucketName, key: S3UploadKeyName)
                }
            })
            } as AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        
        let transferUtility = AWSS3TransferUtility.default()
        
        transferUtility.uploadFile(uploadFileUrl, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHandler: completionHandler).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("Error: %@", error.localizedDescription);
                //self.statusLabel.text = "Failed"
            }
            
            if let _ = task.result {
                print("Upload Started")
            }
            
            return nil;
        }

    }

    
    func savePostToDatabase(bucket: String, key: String) {
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.default()
        let post = Post()
        
        post?.id = NSUUID().uuidString
        post?.bucket = bucket
        post?.filename = key
        post?.userId = identityId
        
        if (!self.setMessage.text!.isEmpty) {
            post?.message = self.setMessage.text!
        } else {
            post?.message = nil //we cannot save a message that is an empty string
        }
        print("Step 1")
        mapper.save(post!).continueWith { (task:AWSTask) -> AnyObject? in
             print("Step 2")
            if (task.error != nil) {
                 print("Step 3")
                print(task.error)
            }

            
            DispatchQueue.main.async(execute: {
                self.displayAlert(title: "Saved", message: "Your post has been saved")
            })
            
            return nil
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction((UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        })))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}







//marks: --------------------------------------------------------------------------------------------

/*class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    
    var activityIndicator = UIActivityIndicatorView() //spinner to show uploading is under process
    
    let S3BucketName = "shareme-project"
    
    @IBOutlet var imagePost: UIImageView!
    
    @IBOutlet var setMessage: UITextField!
    
    @IBAction func chooseAnImage(_ sender: Any) {
        
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        
        self.present(image, animated: true, completion: nil)
    }

    
  /*  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.dismiss(animated: true, completion:nil)
        picker.allowsEditing = true
        imagePost.image = image
    }*/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [AnyHashable: Any]) {
        var chosenImage: UIImage? = info[UIImagePickerControllerOriginalImage] as! UIImage?
        imagePost.image = chosenImage
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    @IBAction func postAnImage(_ sender: Any)
    {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let S3UploadKeyName = NSUUID().uuidString + ".png"
        var location = ""
        
        if let data = UIImagePNGRepresentation(self.imagePost.image!) {
            location = databaseService.getDocumentsDirectory().appendingPathComponent(S3UploadKeyName)
            do {
                try data.write(to: URL(fileURLWithPath: location), options: .atomic)
            } catch {
                print(error)
            }
        } else {
            self.displayAlert(title: "Error", message: "Could not process selected image. UIImagePNGRepresentation failed.")
            return
        }
        
        let uploadFileUrl = NSURL.fileURL(withPath: location)
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
            print("Progress is: %f", progress.fractionCompleted)
        }
        
        let completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                if error != nil {
                    print(error)
                    self.displayAlert(title: "Could not post image", message: "Please try again later")
                } else {
                    self.savePostToDatabase(bucket: self.S3BucketName, key: S3UploadKeyName)
                }
            })
            } as AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        
        let transferUtility = AWSS3TransferUtility.default()
        
        transferUtility.uploadFile(uploadFileUrl, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHandler: completionHandler).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("Error: %@", error.localizedDescription);
                //self.statusLabel.text = "Failed"
            }
            
            if let _ = task.result {
                print("Upload Started")
            }
            
            return nil;
        }
    }
 
    func savePostToDatabase(bucket: String, key: String) {
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.default()
        let post = Post()
        
        post?.id = NSUUID().uuidString
        post?.bucket = bucket
        post?.filename = key
        post?.userId = identityId
        
        if (!self.setMessage.text!.isEmpty) {
            post?.message = self.setMessage.text!
        } else {
            post?.message = nil //we cannot save a message that is an empty string
        }
        
        mapper.save(post!).continueWith { (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            DispatchQueue.main.async(execute: {
                self.displayAlert(title: "Saved", message: "Your post has been saved")
            })
            
            return nil
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction((UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        })))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}*/
