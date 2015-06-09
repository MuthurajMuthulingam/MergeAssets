//
//  HomeViewController.swift
//  MergeVideosSwift
//
//  Created by Muthuraj M on 6/6/15.
//  Copyright (c) 2015 Muthuraj Muthulingam. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import AssetsLibrary

class HomeViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate , MPMediaPickerControllerDelegate , AVAudioPlayerDelegate {

    
    @IBOutlet weak var audioToBePlayedButton: UIButton!
    
    @IBOutlet weak var video1ToBeMerged: UIButton!
    
    @IBOutlet weak var video2ToBeMerged: UIButton!
    
    @IBOutlet weak var mergeVideosButton: UIButton!
    
    @IBOutlet weak var audioPlayerView: UIView!
    
    @IBOutlet weak var video1ImagePreview: UIImageView!
    
    @IBOutlet weak var video2ImagePreview: UIImageView!
    
    @IBOutlet weak var mergedVideoPreview: UIImageView!
    
    @IBOutlet weak var playMusicButton: UIBarButtonItem!
    
    @IBOutlet weak var musicSlider: UISlider!
    
    @IBOutlet weak var musicPlayerToolbar: UIToolbar!
    
    var videoStorageCount:Int!
    
    
    var firstVideoURL:NSURL = NSURL()
    var secondVideoURL:NSURL = NSURL()
    var audioURL:NSURL = NSURL()
    var timer:NSTimer!
    
    var audioPlayer:AVAudioPlayer!
    
    var isFirstVideoSelected:Bool = false
    
    // Mark: Music button Clicked
    
    @IBAction func selectMusicButtonClicked(sender: UIButton) {
        
        // Do open the media Library to select the music
        // Play it after selction in background
        
        self.openMediaPlayerPickerToSelectMusicFile()
        
    }
    
    // Mark : Video 1 to me merged Button Clicked
    
    @IBAction func video1ButtonClicked(sender: UIButton) {
        
        // Do open the media library to select the first Video To be merged.
        // have a refrence to selected Video for merging
        
        self.openMediaLibrary()
    }
    
    // Mark : Video 2 to me merged Button Clicked
    
    @IBAction func video2ButtonClicked(sender: UIButton) {
        
        // Do open the media library to select the second Video To be merged.
        // have a refrence to selected Video for merging
        
        self.openMediaLibrary()
    }
    
    // Mark: Create MPMoviePlayer add it to view 
    
    func createImagePreviewFromSelectedVideo(videoUrl:NSURL,imageViewToUpdatePreviewImage:UIImageView) {
        
        var avAsset:AVAsset = AVAsset.assetWithURL(videoUrl) as! AVAsset
    
        let avImageAssetGenerator:AVAssetImageGenerator = AVAssetImageGenerator(asset: avAsset)
        let time:CMTime = CMTimeMakeWithSeconds(0.0, 600)
        var error:NSError
        var actualTime:CMTime
        avImageAssetGenerator.maximumSize = CGSizeMake(imageViewToUpdatePreviewImage.frame.size.width, imageViewToUpdatePreviewImage.frame.size.height)
        let imgRef:CGImageRef = avImageAssetGenerator.copyCGImageAtTime(time, actualTime: nil, error: nil)
        let imageWithRequiredOrientation:CGImageRef = CGImageCreateWithImageInRect(imgRef, CGRectMake(0, 0, imageViewToUpdatePreviewImage.frame.size.width, imageViewToUpdatePreviewImage.frame.size.height))
        let image:UIImage = UIImage(CGImage: imageWithRequiredOrientation)!
        //let mirroredImage:UIImage = UIImage(CGImage: image.CGImage, scale: image.scale, orientation: UIImageOrientation.DownMirrored)!
        
        imageViewToUpdatePreviewImage.image = image
    }
    
    
    // Mark: Merge Button Clicked
    
    @IBAction func mergeButtonClicked(sender: UIButton) {
        
        // Do start merging the selected Videos and Music
        
        if(self.validateAssetDetails()) {
            
            self.videoStorageCount = self.videoStorageCount+1;
            
            self.showLoading("Merging...")
            
            let weakSelf:HomeViewController = self
            
            let myQueue:dispatch_queue_t = dispatch_queue_create("myQueue", nil)
            dispatch_async(myQueue, { () -> Void in
                var firstVideoAsset:AVAsset = AVAsset.assetWithURL(weakSelf.firstVideoURL) as! AVAsset
                var secondVideoAsset:AVAsset = AVAsset.assetWithURL(weakSelf.secondVideoURL) as! AVAsset
                var audioAsset:AVAsset = AVAsset.assetWithURL(weakSelf.audioURL) as! AVAsset
                
                var mixComposition = AVMutableComposition()
                var firstTrack:AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID.allZeros)
                //addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                var firstAssetTracks:NSArray = firstVideoAsset.tracksWithMediaType(AVMediaTypeVideo)
                firstTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: firstVideoAsset.duration), ofTrack:firstAssetTracks[0] as! AVAssetTrack, atTime: kCMTimeZero, error: nil)
                var secondAssetTracks:NSArray = secondVideoAsset.tracksWithMediaType(AVMediaTypeVideo)
                firstTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: secondVideoAsset.duration), ofTrack:secondAssetTracks[0] as! AVAssetTrack, atTime: kCMTimeZero, error: nil)
                
                // add Audio Track into the composition
                
                var audioTrack:AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID.allZeros)
                var audioTracks:NSArray = audioAsset.tracksWithMediaType(AVMediaTypeAudio) as NSArray
                audioTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: CMTimeAdd(firstVideoAsset.duration, secondVideoAsset.duration)), ofTrack: audioTracks[0] as! AVAssetTrack, atTime: kCMTimeZero, error: nil)
                
                // Get the Dirctory path To Store the Converted File
                
                var paths:NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                var documentDirectoryString:String = paths[0] as! String
                var fileName:String = "myMovie\(weakSelf.videoStorageCount)1.mov"
                var documentPath = documentDirectoryString.stringByAppendingPathComponent(fileName)
                var fileURL:NSURL = NSURL(fileURLWithPath: documentPath)!
                
                // Create the Export the file to particular file Path
                
                let avAssetExporterSession:AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
                avAssetExporterSession.outputURL = fileURL
                avAssetExporterSession.outputFileType = AVFileTypeQuickTimeMovie
                avAssetExporterSession.shouldOptimizeForNetworkUse = true
                avAssetExporterSession.exportAsynchronouslyWithCompletionHandler { () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakSelf.exportedDidFinish(avAssetExporterSession)
                    })
                }
            })
            
        } else {
            self.showAlert("Enter All assets...")
        }
        
        
    }
    
    func exportedDidFinish(avAssetExporterSession:AVAssetExportSession) {
        
        if(avAssetExporterSession.status == AVAssetExportSessionStatus.Completed) {
            var fileURL:NSURL = avAssetExporterSession.outputURL
            var assetLibrary:ALAssetsLibrary = ALAssetsLibrary()
            if(assetLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL)) {
                
                typealias ALAssetsLibraryWriteVideoCompletionBlock = (NSURL!, NSError!) -> Void
                var complete : ALAssetsLibraryWriteVideoCompletionBlock = {reason in println(" this is reason \(reason)")}
                assetLibrary.writeVideoAtPathToSavedPhotosAlbum(fileURL, completionBlock: complete)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.hideLoading()
                    self.showAlert("successfully merged and stored in library at path \(fileURL)")
                    self.createImagePreviewFromSelectedVideo(fileURL, imageViewToUpdatePreviewImage: self.mergedVideoPreview)
                    self.pauseAudio()
                    self.playVideo(fileURL)
                })
                
            }
        } else if(avAssetExporterSession.status == AVAssetExportSessionStatus.Exporting) {
            println("reason exporting ")
        } else if(avAssetExporterSession.status == AVAssetExportSessionStatus.Failed) {
            println("reason failed \(avAssetExporterSession.error)")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showAlert("failed Merging \(avAssetExporterSession.error)")
            })
        } else if(avAssetExporterSession.status == AVAssetExportSessionStatus.Cancelled) {
            println("reason cancelled ")
        } else if(avAssetExporterSession.status == AVAssetExportSessionStatus.Waiting) {
            println("reason waiting ")
        } else {
            println("reason unknown ")
        }
    }
    
    // Mark: Validate the inputs before merge
    
    func validateAssetDetails() -> Bool {
        
        if((self.firstVideoURL.absoluteString != nil) && (self.secondVideoURL.absoluteString != nil) && (self.audioURL.absoluteString != nil)) {
            return true
        }
        return false
    }
    
    // Mark: Select Audio from Media Library
    
    func openMediaLibrary() {
        
        var mediaPicker:UIImagePickerController = UIImagePickerController()
        
        mediaPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        mediaPicker.delegate = self
        print("Media Types \(UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.Camera))")
        
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)) {
            var mediaType:AnyObject = kUTTypeMovie as AnyObject
            mediaPicker.mediaTypes = [mediaType]
        } else {
        
            self.showAlert("Media Type not available...")
        }
        
        self.presentViewController(mediaPicker, animated:true, completion: nil)
    }
    
    // Mark: Select Audio File
    
    func openMediaPlayerPickerToSelectMusicFile() {
        
        var mediaPlayerPickerController:MPMediaPickerController = MPMediaPickerController(mediaTypes: MPMediaType.Music)
        mediaPlayerPickerController.prompt = "Select Music"
        mediaPlayerPickerController.delegate = self
        self .presentViewController(mediaPlayerPickerController, animated: true, completion: nil)
    }
    
    // Mark: Play Audio With URL
    
    func playAudio(audioFileURL:NSURL) {
        
        if (audioURL.absoluteString != nil) {
            self.updateMusicPlayerToolbar(true)
            print("Song URL \(audioFileURL.absoluteString)")
            prepareAudioToPlay(audioFileURL)
            audioPlayer.play()
            startTimer()
        } else {
            self.showAlert("Select a Music to play")
        }
     }
    
    // Mark: Pause Audio
    
    func pauseAudio() {
        self.audioPlayer.pause()
        self.updateMusicPlayerToolbar(false)
    }
    
    // Mark: Prepare Audio to play
    
    func prepareAudioToPlay(audioFileURL:NSURL) {
        
        // Keep audio alive in Background
        
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        var error:NSError?
        self.audioPlayer = AVAudioPlayer(contentsOfURL: audioFileURL, error: &error)
        self.audioPlayer.delegate = self
        musicSlider.maximumValue = CFloat(audioPlayer.duration)
        musicSlider.minimumValue = 0.0
        musicSlider.value = 0.0
        self.audioPlayer.prepareToPlay()
        
    }
    
    // Mark: Start Timer to update Slider Value
    
    func startTimer() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update:"), userInfo: nil,repeats: true)
            timer.fire()
        }
    }
    
    
    func stopTimer() {
        timer.invalidate()
        
    }
    
    // Mark: Timer will call this method to update slider Value
    
    func update(timer: NSTimer) {
        if !audioPlayer.playing {
            return
        }
        
        musicSlider.value = CFloat(audioPlayer.currentTime)
        
    }
    
    // Mark: UI to normal stage after Music Finishes Playing
    
    func updateUserInterfaceToInitialState() {
        self.updateMusicPlayerToolbar(false)
        musicSlider.value = 0
    }
    
    // Mark: Play Video With URL
    
    func playVideo(videoFileURL:NSURL) {
        
        var moviePlayer:MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: videoFileURL)
        self.presentMoviePlayerViewControllerAnimated(moviePlayer)
    }
    
    // Image Picker Delegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        var infoDict:NSDictionary = info as NSDictionary
        var url:NSURL = infoDict.objectForKey("UIImagePickerControllerMediaURL") as! NSURL
        var urlValue:NSURL = url as NSURL
        
        if(isFirstVideoSelected) {
            secondVideoURL = urlValue
            self.createImagePreviewFromSelectedVideo(secondVideoURL, imageViewToUpdatePreviewImage: self.video2ImagePreview)
        } else {
            firstVideoURL = urlValue
            isFirstVideoSelected = true
            self.createImagePreviewFromSelectedVideo(firstVideoURL, imageViewToUpdatePreviewImage: self.video1ImagePreview)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Media Player Delegate Methods
    
    func mediaPicker(mediaPicker: MPMediaPickerController!, didPickMediaItems mediaItemCollection: MPMediaItemCollection!) {
    
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            var selectedSongs:NSArray = mediaItemCollection.items as NSArray
            if(selectedSongs.count == 1) {
                var mediaItem:MPMediaItem = selectedSongs[0] as! MPMediaItem
                var songURL:NSURL = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
                self.audioURL = songURL
                self.playAudio(self.audioURL)
            }
        })
        
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Mark: Play Audio related Actions
    
    @IBAction func playMusicClicked(sender: UIBarButtonItem) {
        
        if(self.audioURL.absoluteString != nil) {
            
            playAudio(self.audioURL)
        } else {
            self.showAlert("Please Select a Music to Play")
        }
    }
    
    // Mark: Update Music Player Toolbar
    
    func updateMusicPlayerToolbar(isStartButton:Bool) {
        
        var items = [AnyObject]()
        items = self.musicPlayerToolbar.items!
        
        if isStartButton {
            items[0] = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: "stopMusic:")
        } else {
            items[0] = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: "startMusic:")
        }
        self.musicPlayerToolbar.items = items
    }
    
    func stopMusic(sender:UIBarButtonItem) {
        self.pauseAudio()
    }
    
    func startMusic(sender:UIBarButtonItem) {
        
        if (self.audioURL.absoluteString != nil) {
            
            self.playAudio(self.audioURL)
        } else {
            self.showAlert("Select a Music to play")
        }
        
    }
    
    // Mark: Slider Value Changing
    
    @IBAction func sliderValueChangedByUser(sender: UISlider) {
        
        print("slider Value \(sender.value)")
        if(audioPlayer != nil) {
            audioPlayer.currentTime = Double(sender.value)
        }
        
    }
    
    // Mark: Store saved VideoIndex to preferences
    
    func storeIndexToPreferences(index:Int) -> Bool {
        let pref:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        pref.setInteger(index, forKey: "storedVideoIndex")
        return true
    }
    
    // Mark: Retirve saved VideoIndex to preferences
    
    func retriveIndexFromPreferences() -> Int {
        let pref:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let index:Int = pref.integerForKey("storedVideoIndex")
        return index
    }
    
    // Mark: Audio Player Delegates
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer!) {
        
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        stopTimer()
        updateUserInterfaceToInitialState()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        musicSlider.value = 0
        musicSlider.userInteractionEnabled = true
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if(self.retriveIndexFromPreferences() > 0) {
            self.videoStorageCount = self.retriveIndexFromPreferences()
        } else {
            self.videoStorageCount = 0
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if(self.storeIndexToPreferences(self.videoStorageCount)) {
            println("video Index Stored ")
        } else {
            println("video Index Not Stored ")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
