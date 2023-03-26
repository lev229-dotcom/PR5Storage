import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

final FirebaseFirestore fireStore = FirebaseFirestore.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void loadImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, dialogTitle: 'Выбор файла');
    if (result != null) {
      final size = result.files.first.size;

      Uint8List? uploadfile = result.files.single.bytes;

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(result.files.single.name);
      UploadTask uploadTask = ref.putData(uploadfile!);
      uploadTask.then((res) async {
        String url = (await ref.getDownloadURL()).toString();
        addImage(result.files.single.name, size.toString(), url);
      });
    }
  }

  Future<void> addImage(String name, String widthandlength, String url) async {
    final image = fireStore.collection("image");

    return await image
        .add({'name': name, 'widthandlength': widthandlength, 'url': url})
        .then((value) => print("image added"))
        .catchError((error) => print(error.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
                stream: fireStore.collection("image").snapshots(),
                builder: (context, snapshot) {
                  List<Widget> childrenVal = <Widget>[];
                  if (snapshot.hasData) {
                    childrenVal = <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < snapshot.data!.docs.length; i++)
                            Column(
                              children: [
                                Image.network(snapshot.data?.docs
                                    .elementAt(i)
                                    .get("url")),
                                Text(
                                    "Имя: ${snapshot.data?.docs.elementAt(i).get("name")}",
                                    style: TextStyle(fontSize: 18)),
                                Text(
                                    "Url: ${snapshot.data?.docs.elementAt(i).get("url")}",
                                    style: TextStyle(fontSize: 18)),
                                Text(
                                    "Размер картинки: ${snapshot.data?.docs.elementAt(i).get("widthandlength")}",
                                    style: TextStyle(fontSize: 18)),
                                SizedBox(
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      deleteItem(
                                          snapshot.data?.docs.elementAt(i).id,
                                          snapshot.data?.docs
                                              .elementAt(i)
                                              .get("url"));
                                    },
                                    child: const Text(
                                      'Удалить',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ];
                  }

                  return Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: childrenVal,
                  ));
                }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadImage,
        tooltip: 'Прочитать файл',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> deleteItem(String? id, String url) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(url);
    ref.delete();
    final item = fireStore.collection("image");
    item
        .doc(id)
        .delete()
        .then(
          (value) => print("Image deleted"),
        )
        .catchError((error) => print(error.toString()));
    ;
  }
}

class Model {
  final String url;
  final String name;
  final int widthandlength;

  Model(this.url, this.name, this.widthandlength);
}
