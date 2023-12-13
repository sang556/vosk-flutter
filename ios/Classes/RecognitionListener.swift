//
//by Sanger

@objc protocol RecognitionListener {
    
    func onPartialResult(_ hypothesis: String);
    
    func onResult(_ hypothesis: String);
    
    func onFinalResult(_ hypothesis: String);
    
    func onError(_ error: Error);
    
    func onTimeout();
}
