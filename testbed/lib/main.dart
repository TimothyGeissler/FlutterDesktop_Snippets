// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:menubar/menubar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:window_size/window_size.dart' as window_size;

import 'package:vertical_tabs/vertical_tabs.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import 'keyboard_test_page.dart';

// The shared_preferences key for the testbed's color.
const _prefKeyColor = 'color';

void main() {
  // Try to resize and reposition the window to be half the width and height
  // of its screen, centered horizontally and shifted up from center.
  WidgetsFlutterBinding.ensureInitialized();
  window_size.getWindowInfo().then((window) {
    if (window.screen != null) {
      final screenFrame = window.screen.visibleFrame;
      final width = math.max((screenFrame.width / 2).roundToDouble(), 800.0);
      final height = math.max((screenFrame.height / 2).roundToDouble(), 600.0);
      final left = ((screenFrame.width - width) / 2).roundToDouble();
      final top = ((screenFrame.height - height) / 3).roundToDouble();
      final frame = Rect.fromLTWH(left, top, width, height);
      window_size.setWindowFrame(frame);
      window_size.setWindowMinSize(Size(0.8 * width, 0.8 * height));
      window_size.setWindowMaxSize(Size(1.5 * width, 1.5 * height));
      window_size.setWindowTitle('Code Snippets by T. Geissler');
    }
  });

  runApp(new MyApp());
}

/// Top level widget for the application.
class MyApp extends StatefulWidget {
  /// Constructs a new app with the given [key].
  const MyApp({Key key}) : super(key: key);

  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<MyApp> {
  _AppState() {
    if (Platform.isMacOS || Platform.isLinux) {
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.containsKey(_prefKeyColor)) {
          setPrimaryColor(Color(prefs.getInt(_prefKeyColor)));
        }
      });
    }
  }

  Color _primaryColor = Colors.blue;

  static _AppState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>();

  /// Sets the primary color of the app.
  void setPrimaryColor(Color color) {
    setState(() {
      _primaryColor = color;
    });
    _saveColor();
  }

  void _saveColor() async {
    if (Platform.isMacOS || Platform.isLinux) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyColor, _primaryColor.value);
    }
  }

  /// Rebuilds the native menu bar based on the current state.
  void updateMenubar() {
    setApplicationMenu([
      Submenu(label: 'Color', children: [
        MenuItem(
            label: 'Reset',
            enabled: _primaryColor != Colors.blue,
            shortcut: LogicalKeySet(
                LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace),
            onClicked: () {
              setPrimaryColor(Colors.blue);
            }),
        MenuDivider(),
        Submenu(label: 'Presets', children: [
          MenuItem(
              label: 'Red',
              enabled: _primaryColor != Colors.red,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR),
              onClicked: () {
                setPrimaryColor(Colors.red);
              }),
          MenuItem(
              label: 'Green',
              enabled: _primaryColor != Colors.green,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.alt, LogicalKeyboardKey.keyG),
              onClicked: () {
                setPrimaryColor(Colors.green);
              }),
          MenuItem(
              label: 'Purple',
              enabled: _primaryColor != Colors.deepPurple,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
              onClicked: () {
                setPrimaryColor(Colors.deepPurple);
              }),
        ])
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Any time the state changes, the menu needs to be rebuilt.
    updateMenubar();

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: _primaryColor,
        accentColor: _primaryColor,
      ),
      darkTheme: ThemeData.dark(),
      home: _MyHomePage(
        title: 'My Snippets',
        primaryColor: _primaryColor,
      ),
    );
  }
}

class _MyHomePage extends StatelessWidget {
  _MyHomePage({this.title, this.primaryColor});

  final String title;
  final Color primaryColor;

  List<Tab> mainTabList = [];

  void initState() {
    mainTabList.add(new Tab(child: Text('Flutter'), icon: Icon(Icons.phone)));
    mainTabList.add(new Tab(child: Text('Dart')));
    mainTabList.add(new Tab(child: Text('Javascript')));
    mainTabList.add(new Tab(child: Text('NodeJS')));
    mainTabList.add(new Tab(child: Text('PHP')));
  }

  @override
  Widget build(BuildContext context) {
    initState();
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: GestureDetector(
            onTap: () {
              addMainTab();
            },
            child: Icon(Icons.create_new_folder),
          ),
        ),
        body: Container(
          child: verticalTabs(context, primaryColor),
        ));
  }

  void addMainTab() {
    print("Add lang Tab");
    mainTabList.add(new Tab(child: Text('PHP2')));
  }

  Widget verticalTabs(BuildContext context, Color primaryColor) {
    return VerticalTabs(
      tabsWidth: 200,
      tabsElevation: 10,
      indicatorColor: primaryColor,
      selectedTabBackgroundColor: primaryColor.withAlpha(50),
      direction: TextDirection.ltr,
      contentScrollAxis: Axis.vertical,
      changePageDuration: Duration(milliseconds: 500),
      tabs: mainTabList,
      contents: <Widget>[
        verticalInnerTabs(context, primaryColor),
        verticalInnerTabs(context, primaryColor),
        verticalInnerTabs(context, primaryColor),
        verticalInnerTabs(context, primaryColor),
        verticalInnerTabs(context, primaryColor),
      ],
    );
  }

  Widget verticalInnerTabs(BuildContext context, Color primaryColor) {
    return VerticalTabs(
      tabsWidth: 200,
      tabsElevation: 5,
      indicatorColor: primaryColor,
      selectedTabBackgroundColor: primaryColor.withAlpha(50),
      direction: TextDirection.ltr,
      contentScrollAxis: Axis.vertical,
      changePageDuration: Duration(milliseconds: 500),
      tabs: <Tab>[
        Tab(
          child: Text("Tab1"),
        ),
        Tab(
          child: Text("Tab2"),
        ),
        Tab(
          child: Text("Tab3"),
        ),
      ],
      contents: <Widget>[
        tabsContentInfo("yehaw1", "description", '''Widget tabsContent(String caption, [String description = '']) {
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(20),
    color: Colors.black12,
    child: Column(
      children: <Widget>[
        Text(
          caption,
          style: TextStyle(fontSize: 25),
        ),
        Divider(
          height: 20,
          color: Colors.black45,
        ),
        Text(
          description,
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    ),
  );
}
'''),
        tabsContent("yehaw2"),
        tabsContent("yehaw3"),
      ],
    );
  }
}

Widget tabsContentInfo(String header, [String description, String text]) {
  TextEditingController descController = new TextEditingController();
  TextEditingController codeController = new TextEditingController();
  descController.text = description;
  codeController.text = text;
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(20),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              header,
              style: TextStyle(fontSize: 25),
            ),
            GestureDetector(
              onTap: () {
                print("edit title");
              },
              child: Icon(Icons.edit),
            )
          ],
        ),
        Divider(
          height: 20,
          color: Colors.black45,
        ),
        TextField(
          controller: descController,
          autofocus: false,
          //maxLines: 8,
          decoration: InputDecoration(
            labelText: "Description",
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: HighlightView(
                      // The original code to be highlighted
                      text,
                      // Specify language
                      // It is recommended to give it a value for performance
                      language: 'dart',
                      // Specify highlight theme
                      // All available themes are listed in `themes` folder
                      theme: githubTheme,
                      // Specify padding
                      padding: EdgeInsets.all(12),
                      // Specify text style
                      textStyle: TextStyle(
                        fontFamily: 'My awesome monospace font',
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              )
            )
          )
        )
      ],
    ),
  );
}

Widget tabsContent(String caption, [String description = '']) {
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(20),
    color: Colors.black12,
    child: Column(
      children: <Widget>[
        Text(
          caption,
          style: TextStyle(fontSize: 25),
        ),
        Divider(
          height: 20,
          color: Colors.black45,
        ),
        Text(
          description,
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    ),
  );
}

Widget tabs(BuildContext context) {
  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.directions_car)),
            Tab(icon: Icon(Icons.directions_transit)),
            Tab(icon: Icon(Icons.directions_bike)),
          ],
        ),
      ),
    ),
  );
}

/// A widget containing controls to test the file chooser plugin.
class FileChooserTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        new FlatButton(
          child: const Text('SAVE'),
          onPressed: () {
            showSavePanel(suggestedFileName: 'save_test.txt').then((result) {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.save, result)),
              ));
            });
          },
        ),
        new FlatButton(
          child: const Text('OPEN'),
          onPressed: () async {
            String initialDirectory;
            initialDirectory = (await getApplicationDocumentsDirectory()).path;
            final result = await showOpenPanel(
                allowsMultipleSelection: true,
                initialDirectory: initialDirectory);
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.open, result))));
          },
        ),
        new FlatButton(
          child: const Text('OPEN MEDIA'),
          onPressed: () async {
            final result =
                await showOpenPanel(allowedFileTypes: <FileTypeFilterGroup>[
              FileTypeFilterGroup(label: 'Images', fileExtensions: <String>[
                'bmp',
                'gif',
                'jpeg',
                'jpg',
                'png',
                'tiff',
                'webp',
              ]),
              FileTypeFilterGroup(label: 'Video', fileExtensions: <String>[
                'avi',
                'mov',
                'mpeg',
                'mpg',
                'webm',
              ]),
            ]);
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.open, result))));
          },
        ),
      ],
    );
  }
}

/// A widget containing controls to test the url launcher plugin.
class URLLauncherTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        new FlatButton(
          child: const Text('OPEN ON GITHUB'),
          onPressed: () async {
            const url = 'https://github.com/google/flutter-desktop-embedding';
            if (await url_launcher.canLaunch(url)) {
              final result = await url_launcher.launch(url);
              assert(result);
            }
          },
        ),
      ],
    );
  }
}

/// A widget containing controls to test text input.
class TextInputTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        SampleTextField(),
        SampleTextField(),
      ],
    );
  }
}

/// A text field with styling suitable for including in a TextInputTestWidget.
class SampleTextField extends StatelessWidget {
  /// Creates a new sample text field.
  const SampleTextField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.0,
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        decoration: InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }
}

/// Possible file chooser operation types.
enum _FileChooserType { save, open }

/// Returns display text reflecting the result of a file chooser operation.
String _resultTextForFileChooserOperation(
    _FileChooserType type, FileChooserResult result) {
  if (result.canceled) {
    return '${type == _FileChooserType.open ? 'Open' : 'Save'} cancelled';
  }
  final typeString = type == _FileChooserType.open ? 'opening' : 'saving';
  return 'Selected for $typeString: ${result.paths.join('\n')}';
}
