//
//by Sanger
import Foundation
import AVFoundation

public final class SpeechService {
    
    var recognizer : OpaquePointer!;
    public var sampleRate : Int = 0;
    let BUFFER_SIZE_SECONDS : Float = 0.2;
    var bufferSize : Int = 0;
    var audioEngine : AVAudioEngine!;
    var processingQueue: DispatchQueue!;
    var recognizerThread: RecognizerThread!;

    init(recognizer: OpaquePointer, sampleRate: Float) {
        self.recognizer = recognizer;
        self.sampleRate = Int(sampleRate);
        self.bufferSize = Int(lrintf(Float(self.sampleRate) * 0.2));
        //self.audioEngine = AVAudioEngine();
    }
    
    deinit {
        vosk_recognizer_free(recognizer);
    }
    
    func startListening(listener: RecognitionListener) -> Bool {
        if recognizerThread != nil {
            return false;
        } else {
            self.audioEngine = AVAudioEngine();
            self.recognizerThread = RecognizerThread(listener: listener, audioEngine: audioEngine, recognizer: recognizer, sampleRate: sampleRate);
            self.recognizerThread.start();
            return true;
        }
    }
    
    func startListening(listener: RecognitionListener, timeout: Int) -> Bool {
        if recognizerThread != nil {
            return false;
        } else {
            self.audioEngine = AVAudioEngine();
            self.recognizerThread = RecognizerThread(listener: listener, audioEngine: audioEngine, recognizer: recognizer, timeout: timeout, sampleRate: sampleRate);
            self.recognizerThread.start();
            return true;
        }
    }
    
    func stopRecognizerThread() -> Bool {
        if recognizerThread == nil {
            return false;
        } else {
            do {
                recognizerThread.cancel();
            } catch {
                print("Unable to stop RecognizerThread: \(error.localizedDescription)");
                recognizerThread.cancel();
            }
            recognizerThread = nil;
            return true;
        }
    }
    
    func stop() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .mixWithOthers);
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation);
            self.audioEngine.reset();
        } catch  {

        }
        self.audioEngine.stop();
        return self.stopRecognizerThread();
    }
    
    func cancel() -> Bool {
        if recognizerThread != nil {
            recognizerThread.setPause(paused: true);
        }
        return self.stop();
    }
    
    func shutdown() {
        self.audioEngine.stop();
        self.audioEngine = nil;
    }
    
    func setPause(paused : Bool) {
        if recognizerThread != nil {
            recognizerThread.setPause(paused: paused);
        }
    }
    
    func reset() {
        if recognizerThread != nil {
            recognizerThread.reset();
        }
    }
}

public final class RecognizerThread { // : Thread
    
    var remainingSamples : Int = 0;
    var timeoutSamples : Int = 0;
    static let NO_TIMEOUT : Int = -1;
    var paused : Bool = false;
    var isReset : Bool = false;
    var listener : RecognitionListener!;
    var audioEngine : AVAudioEngine!;
    var recognizer : OpaquePointer!;
    var processingQueue: DispatchQueue!;
    var thread: Thread!;
    
    init(listener: RecognitionListener, audioEngine: AVAudioEngine, recognizer: OpaquePointer, timeout: Int, sampleRate: Int) {
        self.paused = false;
        self.isReset = false;
        self.listener = listener;
        self.audioEngine = audioEngine;
        self.recognizer = recognizer;
        self.processingQueue = DispatchQueue(label: "recognizerQueue");
        if timeout != -1 {
            self.timeoutSamples = timeout * sampleRate / 1000;
        } else {
            self.timeoutSamples = -1;
        }
        
        self.remainingSamples = self.timeoutSamples;
        //self.init(target: self, selector: #selector(run), object: nil);
        //super.init();
        thread = Thread(target: self, selector: #selector(run), object: nil);
    }
    
    convenience init(listener: RecognitionListener, audioEngine: AVAudioEngine, recognizer: OpaquePointer, sampleRate: Int) {
        self.init(listener: listener, audioEngine: audioEngine, recognizer: recognizer, timeout: -1, sampleRate: sampleRate);
    }
    
    func setPause(paused : Bool) {
        self.paused = paused;
    }
    
    func reset() {
        self.isReset = true;
    }
    
    func recognizeData(buffer : AVAudioPCMBuffer) -> String {
        let dataLen = Int(buffer.frameLength * 2);
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: 1);
        if self.paused {
            return "";
        }
        let endOfSpeech = channels[0].withMemoryRebound(to: Int8.self, capacity: dataLen) {
            vosk_recognizer_accept_waveform(recognizer, $0, Int32(dataLen));
        }
        let res = endOfSpeech == 1 ? vosk_recognizer_result(recognizer) : vosk_recognizer_partial_result(recognizer);
        var result = "";
        if res == nil {
            return result;
        }
        
        do{
            result = String(validatingUTF8: res!)!;
        } catch {
            print("recognizeData: Fatal error: Unexpectedly found nil while unwrapping an Optional value: \(error.localizedDescription)");
        }
        DispatchQueue.main.async {
            if endOfSpeech == 1 {
                self.listener.onResult(result);
            } else {
                self.listener.onPartialResult(result);
            }
        }
        
        return result;
    }
    
    func start() {
        if thread != nil {
            thread.start();
        }
    }
    
    func cancel() {
        if thread != nil {
            thread.cancel();
        }
    }
    
    @objc func run() {
        do {
//            if self.audioEngine.isRunning {
//                self.audioEngine.stop();
//            }
//            try self.audioEngine.start();
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker);
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation);
                self.audioEngine.reset();
            } catch  {

            }
            
            //while(self.thread.isExecuting && (self.timeoutSamples == -1 || self.remainingSamples > 0)) {
                let inputNode = self.audioEngine.inputNode;
                let formatInput = inputNode.inputFormat(forBus: 0);
                let sampleRate = formatInput.sampleRate;
                let formatPcm = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: sampleRate, channels: 1, interleaved: true);
            
                //let recognizer = Vosk(model: model, sampleRate: Float(formatInput.sampleRate));
            
                inputNode.installTap(onBus: 0, bufferSize: UInt32(formatInput.sampleRate / 10), format: formatPcm) {
                //AVAudioPCMBuffer: buffer = AVAudioPCMBuffer[bufferSize];
                    buffer, time in self.processingQueue.async {
                        if !self.paused {
                            if self.isReset {
                                vosk_recognizer_reset(self.recognizer);
                                self.isReset = false;
                            }
                            
                            let res = self.recognizeData(buffer: buffer);
                            
//                            DispatchQueue.main.async {
//                                self.listener.onResult(res);
//                            }
                            
                            if self.timeoutSamples != -1 {
                                //self.remainingSamples -= nread;
                            }
                        }
                    }
                }
            // Start the stream of audio data.
            self.audioEngine.prepare();
            try self.audioEngine.start();
            //}

//            if !self.paused {
//                if self.timeoutSamples != -1 && self.remainingSamples <= 0 {
//                    DispatchQueue.main.async {
//                        self.listener.onTimeout();
//                    }
//                } else {
//                    let finalResult = vosk_recognizer_final_result(self.recognizer);
//                    DispatchQueue.main.async {
//                        self.listener.onFinalResult(String(validatingUTF8: finalResult!)!);
//                    }
//                }
//            }
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)");
            DispatchQueue.main.async {
                self.listener.onError(NSError(domain: "IOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording. Microphone might be already in use."]));
            }
        }
    }
}
