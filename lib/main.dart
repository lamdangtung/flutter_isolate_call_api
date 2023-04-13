import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    ReceivePort rp = ReceivePort();
    FlutterIsolate.spawn(callAPI, rp.sendPort);
    rp.asBroadcastStream().listen((event) {
      final res = base64.decode(event);
      Map map = {};
      int index = 0;
      map = Common.int64ReadByte(res, index);
      int countUser = map["result"];
      index = map["index"];
      debugPrint(countUser.toString());
      var users = <User>[];
      for (int i = 0; i < countUser; i++) {
        var user = User.create();
        index = user.readByte(res, index);
        users.add(user);
      }
      for (var user in users) {
        debugPrint(user.toJson().toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

@pragma('vm:entry-point')
Future<void> callAPI(SendPort sp) async {
  final key = "631b6bb8a3608f9da710fef0";
  final dio = Dio();

  try {
    final response = await dio.get("https://dummyapi.io/data/v1/user",
        queryParameters: {"page": 1, "limit": 10},
        options: Options(headers: {"app-id": key}));
    final data = response.data["data"];
    final users = List.from(data).map((e) => User.fromJson(e)).toList();
    List<int> res = [];
    res.addAll(Common.int64GetBytes(users.length));
    for (var user in users) {
      res.addAll(user.toBytes());
    }
    sp.send(base64.encode(res));
  } catch (e) {
    sp.send(e.toString());
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    required this.id,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.picture,
  });

  String id;
  String title;
  String firstName;
  String lastName;
  String picture;

  factory User.create() {
    return User(
        id: "id",
        title: "title",
        firstName: "firstName",
        lastName: "lastName",
        picture: "picture");
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        title: json["title"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        picture: json["picture"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "firstName": firstName,
        "lastName": lastName,
        "picture": picture,
      };

  List<int> toBytes() {
    List<int> result = [];

    result.addAll(Common.stringGetBytes(id));

    result.addAll(Common.stringGetBytes(title));

    result.addAll(Common.stringGetBytes(firstName));

    result.addAll(Common.stringGetBytes(lastName));

    result.addAll(Common.stringGetBytes(picture));

    return result;
  }

  int readByte(List<int> buff, int index) {
    Map map;

    // id
    map = Common.stringReadByte(buff, index);
    id = map["result"];
    index = map["index"];

    // title
    map = Common.stringReadByte(buff, index);
    title = map["result"];
    index = map["index"];

    // firstName
    map = Common.stringReadByte(buff, index);
    firstName = map["result"];
    index = map["index"];

    // lastName
    map = Common.stringReadByte(buff, index);
    lastName = map["result"];
    index = map["index"];

    // picture
    map = Common.stringReadByte(buff, index);
    picture = map["result"];
    index = map["index"];

    return index;
  }
}

class Common {
  static List<int> int64GetBytes(int value) {
    ByteData bd = new ByteData(8);
    bd.setInt64(0, value);
    return bd.buffer.asUint8List();
  }

  static Map int64ReadByte(List<int> buff, int index) {
    Int8List list = Int8List.fromList(buff.getRange(index, index + 8).toList());
    index += 8;
    return {"result": list.buffer.asByteData().getUint64(0), "index": index};
  }

  static List<int> boolGetBytes(bool value) {
    List<int> result = [];
    result.add((value ? 1 : 0));
    return result;
  }

  static Map boolReadByte(List<int> buff, int index) {
    bool result = (buff[index] == 1);
    index += 1;
    return {"result": result, "index": index};
  }

  static List<int> stringGetBytes(String value) {
    List<int> result = [];
    List<int> buff = utf8.encode(value);

    result.addAll(int64GetBytes(buff.length));
    result.addAll(buff);

    return result;
  }

  static Map stringReadByte(List<int> buff, int index) {
    Map map = int64ReadByte(buff, index);

    // get byte count
    int num = map["result"];
    index = map["index"];

    // get string
    List<int> strBuff = buff.sublist(index, index + num);
    String result = utf8.decode(strBuff);
    index += num;

    return {"result": result, "index": index};
  }
}
