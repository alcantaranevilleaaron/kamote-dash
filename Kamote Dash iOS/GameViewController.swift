//
//  GameViewController.swift
//  Kamote Dash iOS
//
//  Created by Neville Aaron Alcantara on 9/10/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private var presentedScene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView

        // Match the scene's coordinate space exactly to the device's point size.
        // This avoids aspectFill cropping the top/bottom of the scene, which was
        // pushing HUD content above the visible area on some device sizes.
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        presentedScene = scene

        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let skView = self.view as? SKView else { return }
        let newSize = skView.bounds.size
        if let scene = presentedScene, scene.size != newSize {
            scene.size = newSize
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
