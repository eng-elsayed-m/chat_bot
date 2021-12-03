// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:sound_stream/sound_stream.dart';
// import 'package:dialogflow_grpc/dialogflow_grpc.dart';
// import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2beta1/session.pb.dart';

// class Chat extends StatefulWidget {
//   const Chat({Key? key}) : super(key: key);

//   @override
//   _ChatState createState() => _ChatState();
// }

// class _ChatState extends State<Chat> {
//   final List<ChatMessage> _messages = <ChatMessage>[];
//   final TextEditingController _textController = TextEditingController();

//   bool _isRecording = false;

//   RecorderStream recorder = RecorderStream();
//   StreamSubscription? _recorderStatus;
//   StreamSubscription<List<int>>? _audioStreamSubscription;
//   BehaviorSubject<List<int>>? _audioStream;
//   DialogflowGrpcV2Beta1? dialogflow;

//   @override
//   void initState() {
//     super.initState();
//     initPlugin();
//   }

//   @override
//   void dispose() {
//     _recorderStatus?.cancel();
//     _audioStreamSubscription?.cancel();
//     super.dispose();
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlugin() async {
//     _recorderStatus = recorder.status.listen((status) {
//       if (mounted) {
//         setState(() {
//           _isRecording = status == SoundStreamStatus.Playing;
//         });
//       }
//       // Get a Service account
//     });

//     await Future.wait([recorder.initialize()]);

//     // Get a Service account
//     final serviceAccount = ServiceAccount.fromString(
//         await rootBundle.loadString('assets/cred.json'));
//     // Create a DialogflowGrpc Instance
//     dialogflow = DialogflowGrpcV2Beta1.viaServiceAccount(serviceAccount);
//   }

//   Future stopStream() async {
//     try {
//       await _audioStreamSubscription?.cancel();
//       await recorder.stop();
//       await _audioStream?.close();
//     } catch (e) {
//       print(e);
//       return;
//     }
//   }

//   void handleSubmitted(String text) async {
//     if (text.isEmpty) return;
//     _textController.clear();

//     ChatMessage message = ChatMessage(
//       text: text,
//       name: "You",
//       type: true,
//     );

//     setState(() {
//       _messages.insert(0, message);
//     });
//     DetectIntentResponse data = await dialogflow!.detectIntent(text, 'en-US');
//     String fulfillmentText = data.queryResult.fulfillmentText;
//     if (fulfillmentText.isNotEmpty) {
//       ChatMessage botMessage = ChatMessage(
//         text: fulfillmentText,
//         name: "Bot",
//         type: false,
//       );

//       setState(() {
//         _messages.insert(0, botMessage);
//       });
//     }
//   }

//   void handleStream() async {
//     recorder.start();
//     _audioStream = BehaviorSubject<List<int>>();
//     _audioStreamSubscription = recorder.audioStream.listen((data) {
//       _audioStream!.add(data);
//       // print(data);
//     });

//     final biasList = SpeechContextV2Beta1(phrases: [
//       'Dialogflow CX',
//       'Dialogflow Essentials',
//       'Action Builder',
//       'HIPAA'
//     ], boost: 20.0);

//     // See: https://cloud.google.com/dialogflow/es/docs/reference/rpc/google.cloud.dialogflow.v2#google.cloud.dialogflow.v2.InputAudioConfig
//     final config = InputConfigV2beta1(
//         encoding: 'AUDIO_ENCODING_LINEAR_16',
//         languageCode: 'en-US',
//         sampleRateHertz: 16000,
//         singleUtterance: false,
//         speechContexts: [biasList]);

//     // Create an audio InputConfig

//     final responseStream =
//         dialogflow!.streamingDetectIntent(config, _audioStream!);
//     responseStream.listen((data) {
//       //print('----');
//       setState(() {
//         //print(data);
//         String transcript = data.recognitionResult.transcript;
//         String queryText = data.queryResult.queryText;
//         String fulfillmentText = data.queryResult.fulfillmentText;

//         if (fulfillmentText.isNotEmpty) {
//           ChatMessage message = ChatMessage(
//             text: queryText,
//             name: "You",
//             type: true,
//           );

//           ChatMessage botMessage = ChatMessage(
//             text: fulfillmentText,
//             name: "seko",
//             type: false,
//           );

//           _messages.insert(0, message);
//           _textController.clear();
//           _messages.insert(0, botMessage);
//         }
//         if (transcript.isNotEmpty) {
//           _textController.text = transcript;
//         }
//       });
//     }, onError: (e) {
//       //print(e);
//     }, onDone: () {
//       //print('done');
//     });
//   }

//   // The chat interface
//   //
//   //------------------------------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Column(children: <Widget>[
//       Flexible(
//           child: ListView.builder(
//         padding: const EdgeInsets.all(8.0),
//         reverse: true,
//         itemBuilder: (_, int index) => _messages[index],
//         itemCount: _messages.length,
//       )),
//       const Divider(height: 1.0),
//       Container(
//           decoration: BoxDecoration(color: Theme.of(context).cardColor),
//           child: IconTheme(
//             data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Row(
//                 children: <Widget>[
//                   Flexible(
//                     child: TextField(
//                       controller: _textController,
//                       onSubmitted: handleSubmitted,
//                       decoration: const InputDecoration.collapsed(
//                           hintText: "Send a message"),
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: IconButton(
//                       icon: const Icon(Icons.send),
//                       onPressed: () => handleSubmitted(_textController.text),
//                     ),
//                   ),
//                   IconButton(
//                     iconSize: 30.0,
//                     icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
//                     onPressed: _isRecording ? stopStream : handleStream,
//                   ),
//                 ],
//               ),
//             ),
//           )),
//     ]);
//   }
// }

// //------------------------------------------------------------------------------------
// // The chat message balloon
// //
// //------------------------------------------------------------------------------------
// class ChatMessage extends StatelessWidget {
//   const ChatMessage({Key? key, this.text, this.name, this.type})
//       : super(key: key);

//   final String? text;
//   final String? name;
//   final bool? type;

//   List<Widget> otherMessage(context) {
//     return <Widget>[
//       Container(
//         margin: const EdgeInsets.only(right: 16.0),
//         child: const CircleAvatar(child: Text('B')),
//       ),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text(name!, style: const TextStyle(fontWeight: FontWeight.bold)),
//             Container(
//               margin: const EdgeInsets.only(top: 5.0),
//               child: Text(text!),
//             ),
//           ],
//         ),
//       ),
//     ];
//   }

//   List<Widget> myMessage(context) {
//     return <Widget>[
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: <Widget>[
//             Text(name!, style: Theme.of(context).textTheme.subtitle1),
//             Container(
//               margin: const EdgeInsets.only(top: 5.0),
//               child: Text(text!),
//             ),
//           ],
//         ),
//       ),
//       Container(
//         margin: const EdgeInsets.only(left: 16.0),
//         child: CircleAvatar(
//             child: Text(
//           name![0],
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         )),
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: type! ? myMessage(context) : otherMessage(context),
//       ),
//     );
//   }
// }
