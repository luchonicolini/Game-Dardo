//
//  ViewController.swift
//  ATR
//
//  Created by luciano on 05/07/2018.
//  Copyright © 2018 nicolini.com. All rights reserved.
//

import UIKit
import QuartzCore

class GameViewController: UIViewController {
    
    //Global
    var currentValue:Int = 0
    var targetValue :Int = 0
    var score       :Int = 0
    var round       :Int = 0
    var time        :Int = 0
    var timer       :Timer?
    
    
    
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var maxRecordLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //*
     resetGame()
     updateLabel()
     setupSlider()
    }
    
    //logoSlider
    func setupSlider() {
   
    self.slider.setThumbImage(#imageLiteral(resourceName: "SliderThumb-Normal"), for: .normal)
    self.slider.setThumbImage(#imageLiteral(resourceName: "SliderThumb-Highlighted"), for: .highlighted)
    
        let insets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        
        let tackeLeft = #imageLiteral(resourceName: "SliderTrackLeft").resizableImage(withCapInsets: insets)
        let tackeRigth = #imageLiteral(resourceName: "SliderTrackRight").resizableImage(withCapInsets: insets)
        
        self.slider.setMaximumTrackImage(tackeLeft, for: .normal)
        self.slider.setMinimumTrackImage(tackeRigth, for: .normal)
        
    }
    
    //alert de puntuacion
    @IBAction func showAlert(_ sender: UIButton) {
        
    //difrenciaValue
        let difference:Int = abs(self.currentValue - self.targetValue)
        var point = 100 - difference
        
        //Swicht
       switch difference {
       case 0:
            title = "Puntuacion perfecta"
            point = Int(10.0*Float(point))
        case 1...5:
            title = "Casi perfecto"
         point = Int(10.0*Float(point))
        case 6...12:
            title = "Te falto poco"
         point = Int(10.0*Float(point))
        default:
            title = "Te alejaste mucho"
        }
        //Mensaje
        let message =
        "has marcado \(point) puntos"
        
        self.score += point
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: {action in self.startNewRound();self.updateLabel()})
       
        alert.addAction(action)
        present(alert,animated: true)
        startNewRound()
        updateLabel()
        
    }
    
    
    @IBAction func slaiderMoved(_ sender: UISlider) {
       // print("el numero es \(sender.value)")
        self.currentValue = Int(sender.value)
        
    }
    
    //ramdonValue
    func startNewRound() {
       self.targetValue = 1 + Int(arc4random_uniform(100))
        self.currentValue = 50
        self.slider.value = Float(self.currentValue)
        self.round += 1
    }
    
    func updateLabel() {
        self.targetLabel.text = "\(self.targetValue)"
        self.scoreLabel.text = "\(self.score)"
        self.roundLabel.text = "\(self.round)"
        self.timeLabel.text = "\(self.time)"
    }
  
    
    @IBAction func restartLabel(_ sender: UIButton) {
        resetGame()
        updateLabel()
        
        let trasition = CATransition()
        trasition.type = kCATransitionFade
        trasition.duration = 1
        trasition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        self.view.layer.add(trasition, forKey: nil)
        
    }
    
    func resetGame(){
        //Comprobamos puntuación máxima aquí
        var maxscore = UserDefaults.standard.integer(forKey: "maxscore")
        
        if maxscore < self.score {
            maxscore = self.score
            UserDefaults.standard.set(maxscore, forKey: "maxscore")
        }
        
        self.maxRecordLabel.text = "\(maxscore)"
        
        //Reiniciamos variables de juego
        self.score = 0
        self.round = 0
        self.time = 60
        
        //Reiniciamos el temporizador
        if timer != nil {
            timer?.invalidate()
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        
        self.updateLabel()
        self.startNewRound()
    }
    
    @objc func tick(){
        self.time -= 1
        self.timeLabel.text   = "\(self.time)"
        
        if self.time <= 0 {
            
            self.resetGame()
        }
    }

}
