//
//  Scene.swift
//  what's new
//
//  Created by luciano on 27/07/2018.
//  Copyright © 2018 nicolini.com. All rights reserved.
//

import SpriteKit
import ARKit

class Scene: SKScene {
    
    override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        let hit = nodes(at: location)
        
        if let sprite = hit.first {
            sprite.removeFromParent()
            
        }
    }
}
