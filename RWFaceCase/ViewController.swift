/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SceneKit
import ARKit
import ReplayKit

enum ContentType: Int {
    case none
    case mask
    case glasses
    case pig
}

class ViewController: UIViewController {

  // MARK: - Properties
    var anchorNode: SCNNode?
    var mask: Mask?
    var maskType = MaskType.basic
    var contentTypeSelected: ContentType = .none
    var glasses: Glasses?
    var pig: Pig?
    let sharedRecorder = RPScreenRecorder.shared()
    private var isRecording = false

  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var messageLabel: UILabel!
  
  @IBOutlet weak var recordButton: UIButton!
    
    var session: ARSession {
        return sceneView.session
    }

  // MARK: - View Management

  override func viewDidLoad() {
    super.viewDidLoad()
    sharedRecorder.delegate = self
    setupScene()
    createFaceGeometry()

  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIApplication.shared.isIdleTimerDisabled = true
    resetTracking()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UIApplication.shared.isIdleTimerDisabled = false
    sceneView.session.pause()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  // MARK: - Button Actions

  @IBAction func didTapReset(_ sender: Any) {
    print("didTapReset")
    contentTypeSelected = .none
    resetTracking()
  }

  @IBAction func didTapMask(_ sender: Any) {
    print("didTapMask")
    switch maskType {
    case .basic:
        maskType = .zombie
    case .painted:
        maskType = .basic
    case .zombie:
        maskType = .painted
    }
    mask?.swapMaterials(maskType: maskType)
    resetTracking()
    contentTypeSelected = .mask
  }

  @IBAction func didTapGlasses(_ sender: Any) {
    print("didTapGlasses")
    contentTypeSelected = .glasses
    resetTracking()
  }

  @IBAction func didTapPig(_ sender: Any) {
    print("didTapPig")
    contentTypeSelected = .pig
    resetTracking()
  }

  @IBAction func didTapRecord(_ sender: Any) {
    print("didTapRecord")
    guard sharedRecorder.isAvailable else {
        print("Recording is not available.")
        return
    }
    if !isRecording {
        startRecording()
    } else {
        stopRecording()
    }
  }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {

  // Tag: SceneKit Renderer
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time:
        TimeInterval) {
        // 1
        guard let estimate = session.currentFrame?.lightEstimate else {
            return
        }
        // 2
        let intensity = estimate.ambientIntensity / 1000.0
        sceneView.scene.lightingEnvironment.intensity = intensity
        // 3
        let intensityStr = String(format: "%.2f", intensity)
        let sceneLighting = String(format: "%.2f",
                                   sceneView.scene.lightingEnvironment.intensity)
        // 4
        print("Intensity: \(intensityStr) - \(sceneLighting)")
    }

  // Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for
        anchor: ARAnchor) {
        anchorNode = node
        setupFaceNodeContent()
    }

  // Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for
        anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        updateMessage(text: "Tracking your face.")
        switch contentTypeSelected {
        case .none: break
        case .mask:
            mask?.update(withFaceAnchor: faceAnchor)
        case .glasses:
            glasses?.update(withFaceAnchor: faceAnchor)
        case .pig:
            pig?.update(withFaceAnchor: faceAnchor)
        }
    }
    
  // Tag: ARSession Handling
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("** didFailWithError")
        updateMessage(text: "Session failed.")
    }
    func sessionWasInterrupted(_ session: ARSession) {
        print("** sessionWasInterrupted")
        updateMessage(text: "Session interrupted.")
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        print("** sessionInterruptionEnded")
        updateMessage(text: "Session interruption ended.")
    }
}

// MARK: - Private methods

private extension ViewController {

  // Tag: SceneKit Setup
  func setupScene() {
    // Set the view's delegate
    sceneView.delegate = self

    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true
    // Setup environment
    /* default settings */
    sceneView.automaticallyUpdatesLighting = true
    sceneView.autoenablesDefaultLighting = false
    sceneView.scene.lightingEnvironment.intensity = 1.0
  }

  // Tag: ARFaceTrackingConfiguration
    
    func resetTracking() {
        // 1
        guard ARFaceTrackingConfiguration.isSupported else {
            updateMessage(text: "Face Tracking Not Supported.")
            return
        }
        // 2
        updateMessage(text: "Looking for a face.")
        // 3
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true /* default setting */
        configuration.providesAudioData = false /* default setting */
        // 4
        session.run(configuration, options:
            [.resetTracking, .removeExistingAnchors])
    }

  // Tag: CreateARSCNFaceGeometry
    func createFaceGeometry() {
        updateMessage(text: "Creating face geometry.")
        let device = MTLCreateSystemDefaultDevice()
        
        let maskGeometry = ARSCNFaceGeometry(device: device!)!
        mask = Mask(geometry: maskGeometry, maskType: maskType)
        let glassesGeometry = ARSCNFaceGeometry(device: device!)!
        glasses = Glasses(geometry: glassesGeometry)
        let pigGeometry = ARSCNFaceGeometry(device: device!)!
        pig = Pig(geometry: pigGeometry)
    }

  // Tag: Setup Face Content Nodes
    func setupFaceNodeContent() {
        guard let node = anchorNode else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
        switch contentTypeSelected {
        case .none: break
        case .mask:
            if let content = mask {
                node.addChildNode(content)
            }
        case .glasses:
            if let content = glasses {
                node.addChildNode(content)
            }
        case .pig:
            if let content = pig {
                node.addChildNode(content)
            }
        }
    }

  // Tag: Update UI
  func updateMessage(text: String) {
    DispatchQueue.main.async {
      self.messageLabel.text = text
    }
  }
}

// MARK: - RPPreviewViewControllerDelegate (ReplayKit)
extension ViewController: RPPreviewViewControllerDelegate, RPScreenRecorderDelegate {
    
    // RPScreenRecorderDelegate methods
    func screenRecorder(_ screenRecorder: RPScreenRecorder,
                        didStopRecordingWith previewViewController: RPPreviewViewController?,
                        error: Error?) {
        guard error == nil else {
            print("There was an error recording: \(String(describing:error?.localizedDescription))")
            self.isRecording = false
            return
        }
    }
    
    
    // RPPreviewViewControllerDelegate methods
    func previewControllerDidFinish(_ previewController:
        RPPreviewViewController) {
        print("previewControllerDidFinish")
        dismiss(animated: true)
    }
    
    // Private functions
    private func startRecording() {
        // 1
        self.sharedRecorder.isMicrophoneEnabled = true
        // 2
        sharedRecorder.startRecording( handler: { error in
            guard error == nil else {
                print("There was an error starting the recording: \(String(describing: error?.localizedDescription))")
                return
            }
            // 3
            print("Started Recording Successfully")
            self.isRecording = true
            // 4
            DispatchQueue.main.async {
                self.recordButton.setTitle("[ STOP RECORDING ]", for: .normal)
                self.recordButton.backgroundColor = UIColor.red
            }
        }) }
    
    func stopRecording() {
        // 1
        self.sharedRecorder.isMicrophoneEnabled = false
        // 2
        sharedRecorder.stopRecording( handler: {
            previewViewController, error in
            guard error == nil else {
                print("There was an error stopping the recording: \(String(describing: error?.localizedDescription))")
                return
            }
            // 3 ** UPDATED
            // 3.1
            let alert = UIAlertController(title: "Recording Complete",
                                          message: "Do you want to preview/edit your recording or delete it?", preferredStyle: .alert)
            // 3.2
            let deleteAction = UIAlertAction(title: "Delete",
                                             style: .destructive,
                                             handler: { (action: UIAlertAction) in
                                                self.sharedRecorder.discardRecording(handler: { () -> Void in
                                                    print("Recording deleted.")
                                                })
            })
            // 3.3
            let editAction = UIAlertAction(title: "Edit",
                                           style: .default,
                                           handler: { (action: UIAlertAction) -> Void
                                            in
                                            if let unwrappedPreview = previewViewController {
                                                unwrappedPreview.previewControllerDelegate = self
                                                self.present(unwrappedPreview, animated: true, completion: {})
                                            }
            })
            // 3.4
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
        })
        // 4
        self.isRecording = false
        DispatchQueue.main.async {
            self.recordButton.setTitle("[ RECORD ]", for: .normal)
            self.recordButton.backgroundColor = UIColor(red: 0.0039,
                                                        green: 0.5882, blue: 1, alpha: 1.0) /* #0196ff */
        }
    }
    
    func screenRecorderDidChangeAvailability(_ screenRecorder:
        RPScreenRecorder) {
        recordButton.isEnabled = sharedRecorder.isAvailable
        if !recordButton.isEnabled {
            self.isRecording = false
        }
        // Update the title in code
        if sharedRecorder.isAvailable {
            DispatchQueue.main.async {
                self.recordButton.setTitle("[ RECORD ]", for: .normal)
                self.recordButton.backgroundColor = UIColor(red: 0.0039,
                                                            green: 0.5882,
                                                            blue: 1,
                                                            alpha: 1.0)
            }
        } else {
           
            DispatchQueue.main.async {
                self.recordButton.setTitle("[ RECORDING DISABLED ]",
                                           for: .normal)
                self.recordButton.backgroundColor = UIColor.red
            } }
    }
    
}
