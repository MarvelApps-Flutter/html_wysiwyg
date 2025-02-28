import 'package:flutter/material.dart';
import 'package:html_wysiwyg_textfield/html_wysiwyg_textfield.dart';

import 'webview_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GlobalKey<HtmlWYSIWYGTextFieldState> _keyWysiwyg = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Html WYSIWYG'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                // height: 220,
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                        color: Colors.black), 
                    iconButtonTheme: IconButtonThemeData(
                        style: ButtonStyle(
                            iconColor: WidgetStatePropertyAll(Colors.black))),
                  ),
                  child: HtmlWYSIWYGTextField(
                    height: 300,
                    value: "Your text here...",
                    fontList: const ['11', '12', '13', '14'],
                    onNavigate: (url) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WebViewScreen(url: url),
                        ),
                      );
                    },
                    key: _keyWysiwyg,
                    customToolbar: """
                                  [
                                    ['style', ['bold', 'italic', 'underline', 'clear']],
                                    ['font', ['strikethrough']],
                                    ['fontname', ['fontname']], 
                                    ['fontsize', ['fontsize']],
                                    ['para', ['ul', 'ol']],
                                    ['linkButton', ['customLink']],
                                    ['copyButton', ['customCopy']],
                                    ['pasteButton', ['customPaste']],
                                    ['cutButton', ['customCut']]  
                                    
                                  ]
                                      """,
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}