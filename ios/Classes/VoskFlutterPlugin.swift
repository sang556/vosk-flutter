import Flutter
import UIKit
import AVFoundation

public class VoskFlutterPlugin: NSObject, FlutterPlugin {
    
    var registrar: FlutterPluginRegistrar;
    var channel: FlutterMethodChannel;
    var modelCreateProcessingQueue: DispatchQueue!;
    var modelsMap: Dictionary<String , VoskModel> = [:];
    var recognizersMap: Dictionary<Int, OpaquePointer> = [:];
    var recognitionListener: FlutterRecognitionListener!;
    var speechService: SpeechService!;
    
    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.registrar = registrar;
        self.channel = channel;
        super.init();
          
        //let documentsPath = NSHomeDirectory() + "/Documents"
        modelCreateProcessingQueue = DispatchQueue(label: "createModelQueue");
        recognitionListener = FlutterRecognitionListener(binaryMessenger: registrar.messenger());
    }
    
    deinit {
        for (key, value) in recognizersMap {
            vosk_recognizer_free(value);
            recognizersMap.removeValue(forKey: key);
        }
        
        channel.setMethodCallHandler(nil);
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vosk_flutter", binaryMessenger: registrar.messenger());
        let instance = VoskFlutterPlugin(registrar: registrar, channel: channel);
        registrar.addMethodCallDelegate(instance, channel: channel);
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion);
        case "init":
            
            result(nil);
        case "model.create":
            guard let modelPath: String = call.arguments as? String else {
                result("Please, send 1 string argument, contains model path.");
                return;
            }
            //modelCreateProcessingQueue.async {
            DispatchQueue.main.async {
                do {
                    if !self.modelsMap.contains(where: { $0.key == modelPath }) {
                        let model = VoskModel(modelPath: modelPath);
                        self.modelsMap[modelPath] = model;
                    }
                    self.channel.invokeMethod("model.created", arguments: modelPath);
                } catch var error {
                    let resultMap = ["modelPath": modelPath, "error": error] as [String : Any];
                    self.channel.invokeMethod("model.error", arguments: modelPath);
                }
            }
            result(nil);
        case "recognizer.create":
            let map = call.arguments as? Dictionary<String, Any>;
            let sampleRate = map?["sampleRate"] as? Float ?? 0;
            let modelPath = map?["modelPath"] as? String ?? "";
            let grammar = map?["grammar"] as? String;
            let model = self.modelsMap[modelPath];
            if model == nil {
                result("Couldn't find model with this path. Pls, create model or send correct path.");
                break;
            }
            let recognizerId = recognizersMap.isEmpty ? 1 : recognizersMap.keys.sorted().last! + 1;
            do {
                //let recognizer = Vosk(model: model!, sampleRate: Float(sampleRate));
                let recognizer : OpaquePointer! = grammar == nil ? vosk_recognizer_new(model?.model, sampleRate) : vosk_recognizer_new_grm(model?.model, sampleRate, grammar);
                recognizersMap[recognizerId] = recognizer;
                if (recognizersMap.count > 10) {
                    //if let firstKey = recognizersMap.first?.key {
                    //    recognizersMap.removeValue(forKey: firstKey);
                    //}
                    let firstKey = recognizersMap.keys.sorted().first;
                    //let firstRecognizer = firstKey.map({ ($0, recognizersMap[$0]!) });
                    vosk_recognizer_free(recognizersMap[firstKey!]);
                    //recognizersMap[firstKey!] = nil;
                    recognizersMap.removeValue(forKey: firstKey!);
                }
            } catch var error {
                result("Can't create recognizer.");
                break;
            }
            result(recognizerId);
        case "recognizer.setMaxAlternatives":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let maxAlternatives = map?["maxAlternatives"] as? Int32 ?? 0;
            
            let recognizer = self.getRecognizerById(recognizerId);
            vosk_recognizer_set_max_alternatives(recognizer, maxAlternatives);
            result(nil);
        case "recognizer.setWords":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let words = map?["words"] as? Bool ?? false;
            
            let recognizer = self.getRecognizerById(recognizerId);
            vosk_recognizer_set_words(recognizer, words ? 1 : 0);
            result(nil);
        case "recognizer.setPartialWords":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let partialWords = map?["partialWords"] as? Bool ?? false;
            
            let recognizer = self.getRecognizerById(recognizerId);
            //vosk_recognizer_set_partial_words(recognizer, partialWords ? 1 : 0);
            result(nil);
        case "recognizer.acceptWaveForm":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let bytes = map?["bytes"] as? Array<UInt8> ?? [];
            let floats = map?["floats"] as? Array<UInt8> ?? [];
            
            if bytes.count == 0 && floats.count == 0 {
                result("Didn't find data. Pls, send data.");
                break;
            }
            
            let bytesUint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count);
            bytesUint8Pointer.initialize(from: bytes, count: bytes.count);
            defer {
                bytesUint8Pointer.deinitialize(count: bytes.count);
                bytesUint8Pointer.deallocate();
            }
            let floatsUint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: floats.count);
            floatsUint8Pointer.initialize(from: floats, count: floats.count);
            defer {
                floatsUint8Pointer.deinitialize(count: floats.count);
                floatsUint8Pointer.deallocate();
            }
            
            let recognizer = self.getRecognizerById(recognizerId);
            if bytes.count == 0 {
                result(vosk_recognizer_accept_waveform(recognizer, floatsUint8Pointer, Int32(floats.count)));
            } else {
                result(vosk_recognizer_accept_waveform(recognizer, bytesUint8Pointer, Int32(bytes.count)));
            }
        case "recognizer.getResult":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            
            let recognizer = self.getRecognizerById(recognizerId);
            result(vosk_recognizer_result(recognizer));
        case "recognizer.getPartialResult":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            
            let recognizer = self.getRecognizerById(recognizerId);
            result(vosk_recognizer_partial_result(recognizer));
        case "recognizer.getFinalResult":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            
            let recognizer = self.getRecognizerById(recognizerId);
            result(vosk_recognizer_final_result(recognizer));
        case "recognizer.setGrammar":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let grammar = map?["grammar"] as? String;
            
            let recognizer = self.getRecognizerById(recognizerId);
            //vosk_recognizer_set_grm(recognizer, grammar);
            result(nil);
        case "recognizer.reset":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            
            let recognizer = self.getRecognizerById(recognizerId);
            vosk_recognizer_reset(recognizer);
            result(nil);
        case "recognizer.close":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            
            let recognizer = self.getRecognizerById(recognizerId);
            vosk_recognizer_free(recognizer);
            recognizersMap.removeValue(forKey: recognizerId);
            result(nil);
        case "speechService.init":
            let map = call.arguments as? Dictionary<String, Any>;
            let recognizerId = map?["recognizerId"] as? Int ?? 1;
            let sampleRate = map?["sampleRate"] as? Float ?? 0;
            
            let recognizer = self.getRecognizerById(recognizerId);
            if speechService == nil {
                speechService = SpeechService(recognizer: recognizer, sampleRate: sampleRate);
            } else {
                result("SpeechService instance already exist.");
                break;
            }
            result(nil);
        case "speechService.start":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            result(speechService.startListening(listener: recognitionListener));
        case "speechService.stop":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            result(speechService.stop());
        case "speechService.setPause":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            let paused = call.arguments as? Bool ?? false;
            speechService.setPause(paused: paused);
            result(nil);
        case "speechService.reset":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            speechService.reset();
            result(nil);
        case "speechService.cancel":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            result(speechService.cancel());
        case "speechService.destroy":
            if speechService == nil {
                //throw SpeechServiceNotFound();
                result(SpeechServiceNotFound());
                break;
            }
            speechService.shutdown();
            speechService = nil;
            
            recognizersMap
            result(nil);
        default:
            result(FlutterMethodNotImplemented);
        }
    }
    
    private func getRecognizerById(_ recognizerId: Int)  -> OpaquePointer { //throws
        let recognizer = recognizersMap[recognizerId];
        if recognizer == nil {
            //print("Recognizer with id=%d doesn't exist!", recognizerId);
            fatalError(String(format: "Recognizer with id=%d doesn't exist!", recognizerId));
        }
        //assert(recognizer != nil , String(format: "Recognizer with id=%d doesn't exist!", recognizerId));
        return recognizer!;
    }
}

private final class SpeechServiceNotFound : NSError {
    
    init() {
        super.init(domain: "IOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech service not initialized"]);
    }
    
    required convenience init?(coder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        self.init();
    }
}
