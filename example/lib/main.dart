import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
//import 'package:background_downloader/background_downloader.dart';
import 'package:flowder_ex/flowder_ex.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VoskFlutterDemo(),
    );
  }
}

class VoskFlutterDemo extends StatefulWidget {
  const VoskFlutterDemo({Key? key}) : super(key: key);

  @override
  State<VoskFlutterDemo> createState() => _VoskFlutterDemoState();
}

class _VoskFlutterDemoState extends State<VoskFlutterDemo> {
  static const _textStyle = TextStyle(fontSize: 30, color: Colors.black);
  late LanguageModelDescription _lmi;
  static final _sampleRate = Platform.isAndroid ? 16000 : 44100;

  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();
  final _recorder = Record();

  String? _fileRecognitionResult;
  String? _error;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _recognitionStarted = false;

  // 文件信息
  String fileInfo = '';
  // 下载进度
  double progress = 0.0;
  // 任务状态
  String taskStatus = '';
  // 任务
  //late DownloadTask task;
  //late FileDownloader fileDownloader;
  static const _defaultDownloadDir = "Download";
  static const _fileSuffix = ".zip";
  /*https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
  https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip
  https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip
  https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip
  https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip
  https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip
  https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip
  https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip*/
  List<LanguageModelDescription> modelsList = [
    LanguageModelDescription(lang: "en", name: "vosk-model-small-en-us-0.15", size: 41205931, url: "https://tiandongli.cn/guides/models/vosk-model-small-en-us-0.15.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "zh", name: "vosk-model-small-cn-0.22", size: 43898754, url: "https://tiandongli.cn/guides/models/vosk-model-small-cn-0.22.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "fr", name: "vosk-model-small-fr-0.22", size: 42233323, url: "https://tiandongli.cn/guides/models/vosk-model-small-fr-0.22.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "de", name: "vosk-model-small-de-0.15", size: 46499967, url: "https://tiandongli.cn/guides/models/vosk-model-small-de-0.15.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "ru", name: "vosk-model-small-ru-0.22", size: 46236750, url: "https://tiandongli.cn/guides/models/vosk-model-small-ru-0.22.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "ja", name: "vosk-model-small-ja-0.22", size: 49704573, url: "https://tiandongli.cn/guides/models/vosk-model-small-ja-0.22.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "es", name: "vosk-model-small-es-0.42", size: 39817833, url: "https://tiandongli.cn/guides/models/vosk-model-small-es-0.42.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
    LanguageModelDescription(lang: "pt", name: "vosk-model-small-pt-0.3", size: 32453112, url: "https://tiandongli.cn/guides/models/vosk-model-small-pt-0.3.zip", langText: "", md5: "", obsolete: true, sizeText: "", type: "", version: ""),
  ];

  @override
  void initState() {
    super.initState();

    _lmi = getLanguage("zh");
    //loadModelFromLocal();
    //loadModelFromNetwork();
    loadModelFromDownload();
  }

  ///
  /// 创建语音识别器
  Future<void> createRecognizer(modelPath) async {
    _model = await _vosk.createModel(modelPath);

    _recognizer = await _vosk.createRecognizer(
      model: _model!,
      sampleRate: _sampleRate,
      //grammar: ['one', 'two', 'three'],
    );
  }

  ///
  /// 初始化语音识别服务
  void initSpeechService() {
    //if (Platform.isAndroid) {
      _vosk
          .initSpeechService(_recognizer!) // init speech service
          .then((speechService) =>
          setState(() => _speechService = speechService))
          .catchError((e) => setState(() => _error = e.toString()));
    //}
  }

  void loadModelFromLocal() async {
    final modelPath = await ModelLoader().loadFromAssets('assets/models/${_lmi.name}.zip');
    await createRecognizer(modelPath);
    initSpeechService();
  }

  void loadModelFromNetwork() {
    _modelLoader
        .loadModelsList()
        .then((modelsList) =>
        modelsList.firstWhere((model) => model.name == _lmi.name))
        .then((modelDescription) =>
        _modelLoader.loadFromNetwork(modelDescription.url)) // load model
        .then(
            (modelPath) => _vosk.createModel(modelPath)) // create model object
        .then((model) => setState(() => _model = model))
        .then((_) => _vosk.createRecognizer(
        model: _model!, sampleRate: _sampleRate)) // create recognizer
        .then((value) => _recognizer = value)
        .then((recognizer) {
      initSpeechService();
    }).catchError((e) {
      setState(() => _error = e.toString());
      return null;
    });
  }

  void loadModelFromDownload() async {
    final directory = await getApplicationDocumentsDirectory();
    String modelPath = directory.path + Platform.pathSeparator + _defaultDownloadDir + Platform.pathSeparator + _lmi.name + _fileSuffix;
    final modelName = path.basenameWithoutExtension(modelPath);
    if (!await _modelLoader.isModelAlreadyLoaded(modelName)) {
    //if (!await isVerifyFile(_lmi.fileName)) {
      //modelsList = await _modelLoader.loadModelsList();
      //LanguageModelDescription modelDescription = modelsList.firstWhere((model) => model.name == _lmi.name);
      initSpeechServiceByDownloadFile(_lmi.url);
    } else {
      modelPath = await loadFromLocalFile(modelPath);
      await createRecognizer(modelPath);
      initSpeechService();
    }
  }

  /// Load a model from the app local file. Returns the path to the loaded model.
  ///
  /// By default, this method will not reload an already loaded model, you can
  /// change this behaviour using the [forceReload] flag.
  Future<String> loadFromLocalFile(
      String filePath, {
        bool forceReload = false,
      }) async {
    final modelName = path.basenameWithoutExtension(filePath);
    if (!forceReload && await _modelLoader.isModelAlreadyLoaded(modelName)) {
      final modelPathValue = await _modelLoader.modelPath(modelName);
      log('Model already loaded to $modelPathValue', name: 'ModelLoader');
      return modelPathValue;
    }

    final start = DateTime.now();

    //final bytes = await (assetBundle ?? rootBundle).load(asset);
    final Uint8List bytes = await File(filePath).readAsBytes();
    final decompressionPath = await _extractModel(bytes);

    final decompressedModelRoot = path.join(decompressionPath, modelName);
    log('Model loaded to $decompressedModelRoot in ${DateTime.now().difference(start).inMilliseconds}ms', name: 'ModelLoader',);

    return decompressedModelRoot;
  }

  Future<String> _extractModel(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final decompressionPath = await _defaultDecompressionPath();

    await Isolate.run(() => extractArchiveToDisk(archive, decompressionPath));

    return decompressionPath;
  }

  static Future<String> _defaultDecompressionPath() async => path.join((await getApplicationDocumentsDirectory()).path, 'models');

  ///
  /// 判断文件是否存在及验证文件是否完整(未使用)
  Future<bool> isVerifyFile(fileName) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String localPath = directory.path + Platform.pathSeparator + _defaultDownloadDir;
    final savedDir = Directory(localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      await savedDir.create();
    }

    final file = File(localPath + Platform.pathSeparator + fileName + _fileSuffix);
    //判断文件是否存在及验证文件完整性
    if (!await file.exists() || await file.length() != _lmi.size) {
      return Future.value(false);
    }

    return Future.value(true);
  }

  ///background_downloader插件下载(暂未使用)
  /*initSpeechServiceByDownloadFile1(url) async {
    task = DownloadTask(
        url: url, // 下载地址
        // urlQueryParameters: {'q': 'pizza'},  // 请求参数
        filename: _lmi.name, // 文件名
        //headers: {'myHeader': 'value'},  请求头
        directory: _defaultDownloadDir, // 文件存储目录
        updates: Updates.statusAndProgress, // 更新任务状态和下载进度
        requiresWiFi: true, // 使用wifi
        retries: 5, // 下载的重试次数
        allowPause: true, // 运行暂停
        metaData: 'data for me' // 元数据，可以存储一些对于下载任务有用的信息，方便后续相关操作
    );
    fileDownloader = FileDownloader();
    // 监听下载
    final result = await fileDownloader.download(task, onProgress: (progress) {
      setState(() {
        this.progress = progress;
      });
    }, onStatus: (states) async {
      String msg = '';
      if (states == TaskStatus.complete) {
        msg = '下载完成';
        //  下载完成后，将文件移动到共享目录后，其他应用也可以访问。否则只能在本应用内访问
        //fileDownloader.moveToSharedStorage(task, SharedStorage.downloads);
        final directory = await getApplicationDocumentsDirectory();
        String modelPath = directory.path + Platform.pathSeparator + _defaultDownloadDir + Platform.pathSeparator + _lmi.name + _fileSuffix;
        modelPath = await loadFromLocalFile(modelPath);
        await createRecognizer(modelPath);
        initSpeechService();
      } else if (states == TaskStatus.canceled) {
        msg = '已取消';
        setState(() {
          progress = 0;
        });
      } else if (states == TaskStatus.paused) {
        msg = '已暂停';
      } else if (states == TaskStatus.running) {
        msg = '下载中...';
      } else {
        msg = '下载失败';
      }
      setState(() {
        taskStatus = msg;
      });
    });
  }*/

  ///flowder_ex插件下载
  initSpeechServiceByDownloadFile(url) async {
    final directory = await getApplicationDocumentsDirectory();
    String modelPath = directory.path + Platform.pathSeparator + _defaultDownloadDir + Platform.pathSeparator + _lmi.name + _fileSuffix;

    final options = DownloaderUtils(
      progressCallback: (current, total) {
        setState(() {
          progress = (current / total) * 100;
          debugPrint("current: $current   total: $total");
        });
      },
      file: File(modelPath),
      progress: ProgressImplementation(),
      onDone: () async {
        modelPath = await loadFromLocalFile(modelPath);
        await createRecognizer(modelPath);
        initSpeechService();
      },
      deleteOnCancel: true, accessToken: '',
    );
    await Flowder.download(url, options,);
  }

  ///获取语言模型
  LanguageModelDescription getLanguage(String language) {
    return modelsList.firstWhere((model) => model.lang == language, orElse: ()=> modelsList[0]);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
          body: Center(child: Text("Error: $_error", style: _textStyle)));
    } else if (_model == null) {
      return Scaffold(
          body: Center(child: Text("Loading model...\n${(progress).toStringAsFixed(1)}%", style: _textStyle)));
    } else if (Platform.isAndroid && _speechService == null) {
      return const Scaffold(
        body: Center(
          child: Text("Initializing speech service...", style: _textStyle),
        ),
      );
    } else {
      return Platform.isAndroid || Platform.isIOS ? _androidExample() : _commonExample();
    }
  }

  Widget _androidExample() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (_recognitionStarted) {
                    await _speechService!.stop();
                  } else {
                    await _speechService!.start();
                  }
                  setState(() => _recognitionStarted = !_recognitionStarted);
                },
                child: Text(_recognitionStarted
                    ? "Stop recognition"
                    : "Start recognition")),
            StreamBuilder(
                stream: _speechService!.onPartial(),
                builder: (context, snapshot) => Text(
                    "Partial result: ${snapshot.data.toString()}",
                    style: _textStyle)),
            StreamBuilder(
                stream: _speechService!.onResult(),
                builder: (context, snapshot) => Text(
                    "Result: ${snapshot.data.toString()}",
                    style: _textStyle)),
          ],
        ),
      ),
    );
  }

  Widget _commonExample() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (_recognitionStarted) {
                    await _stopRecording();
                  } else {
                    await _recordAudio();
                  }
                  setState(() => _recognitionStarted = !_recognitionStarted);
                },
                child: Text(
                    _recognitionStarted ? "Stop recording" : "Record audio")),
            Text("Final recognition result: $_fileRecognitionResult",
                style: _textStyle),
          ],
        ),
      ),
    );
  }

  Future<void> _recordAudio() async {
    try {
      await _recorder.start(
          samplingRate: 16000, encoder: AudioEncoder.wav, numChannels: 1);
    } catch (e) {
      _error = e.toString() +
          '\n\n Make sure fmedia(https://stsaz.github.io/fmedia/)'
              ' is installed on Linux';
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _recorder.stop();
      if (filePath != null) {
        final bytes = File(filePath).readAsBytesSync();
        _recognizer!.acceptWaveformBytes(bytes);
        _fileRecognitionResult = await _recognizer!.getFinalResult();
      }
    } catch (e) {
      _error = e.toString() +
          '\n\n Make sure fmedia(https://stsaz.github.io/fmedia/)'
              ' is installed on Linux';
    }
  }
}
