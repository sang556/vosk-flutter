//
//by Sanger
import Foundation
import AVFoundation

#if os(iOS)
import Flutter
import UIKit
import MediaPlayer
#else
import FlutterMacOS
#endif

var errorSink: FlutterEventSink?;
var resultSink: FlutterEventSink?;
var partialSink: FlutterEventSink?;

public final class FlutterRecognitionListener : NSObject, RecognitionListener {
    
    var errorEventChannel : FlutterEventChannel!;
    var resultEventChannel : FlutterEventChannel!;
    var partialEventChannel : FlutterEventChannel!;
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.errorEventChannel = FlutterEventChannel(name: "error_event_channel", binaryMessenger: binaryMessenger);
        self.resultEventChannel = FlutterEventChannel(name: "result_event_channel", binaryMessenger: binaryMessenger);
        self.partialEventChannel = FlutterEventChannel(name: "partial_event_channel", binaryMessenger: binaryMessenger);
        errorEventChannel.setStreamHandler(ErrorFlutterStreamHandler());
        resultEventChannel.setStreamHandler(ResultFlutterStreamHandler());
        partialEventChannel.setStreamHandler(PartialFlutterStreamHandler());
    }
    
    deinit {
        errorEventChannel.setStreamHandler(nil);
        resultEventChannel.setStreamHandler(nil);
        partialEventChannel.setStreamHandler(nil);
    }
    
    func onPartialResult(_ hypothesis: String) {
        if partialSink != nil {
            partialSink?(hypothesis);
        }
    }
    
    func onResult(_ hypothesis: String) {
        if resultSink != nil {
            resultSink?(hypothesis);
        }
    }
    
    func onFinalResult(_ hypothesis: String) {
        if resultSink != nil {
            resultSink?(hypothesis);
        }
    }
    
    func onError(_ error: Error) {
        if errorSink != nil {
            errorSink?(error);
        }
    }
    
    func onTimeout() {
        
    }
}

class ErrorFlutterStreamHandler : NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        errorSink = events;
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        //NotificationCenter.default.removeObserver(self);
        errorSink = nil;
        return nil;
    }
        
    public func sendEvent(event:Any) {
        errorSink?(event);
    }
}

class ResultFlutterStreamHandler : NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        resultSink = events;
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        resultSink = nil;
        return nil;
    }
        
    public func sendEvent(event:Any) {
        resultSink?(event);
    }
}

class PartialFlutterStreamHandler : NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        partialSink = events;
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        partialSink = nil;
        return nil;
    }
        
    public func sendEvent(event:Any) {
        partialSink?(event);
    }
}
