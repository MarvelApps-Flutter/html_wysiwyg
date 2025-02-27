import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HtmlWYSIWYGTextField extends StatefulWidget {
  final String? value;
  final double? height;
  final BoxDecoration? decoration;
  final String? hint;
  final String? customToolbar;
  final Function(String)? returnContent;
  final Function(String)? onNavigate;

  const HtmlWYSIWYGTextField({
    super.key,
    this.value,
    this.height,
    this.decoration,
    this.hint,
    this.customToolbar,
    this.returnContent,
    this.onNavigate,
  });

  @override
  HtmlWYSIWYGTextFieldState createState() => HtmlWYSIWYGTextFieldState();
}

class HtmlWYSIWYGTextFieldState extends State<HtmlWYSIWYGTextField> {
  String text = '';
  late String _page;
  final Key _mapKey = UniqueKey();
  WebViewController? _webViewController;
  late BuildContext _dialogContext;
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  void handleRequest(HttpRequest request) {
    try {
      if (request.method == 'GET' &&
          request.uri.queryParameters['query'] == 'getRawTeXHTML') {
      } else {}
    } catch (e) {
      debugPrint('Exception in handleRequest: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _page = _initPage(widget.customToolbar);
    _webViewController = WebViewController();

    _webViewController!.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController!.addJavaScriptChannel('GetTextSummernote',
        onMessageReceived: (JavaScriptMessage message) async {
      String isi = message.message;

      if (isi.startsWith('http') || isi.startsWith('https')) {
          // Assuming URL starts with http
        _navigateToWebView(isi); // Navigate to WebView
      } else if (isi.startsWith('_showLinkDialog')) {
        _showLinkDialog();
      } else if (isi.startsWith('copy')) {

        String script = '''
        var selectedText = window.getSelection().toString().trim();
        selectedText.replace(/<p>|<\\/p>/g, '\\n')
        .replace(/<div>|<\\/div>/g, '\\n');
        ''';
        try {
          final selectedText = await _webViewController!
              .runJavaScriptReturningResult(script) as String;

          if (selectedText.isNotEmpty) {
              
            String cleanText = selectedText.replaceAll('"', '').trim();
            await Clipboard.setData(ClipboardData(text: cleanText));
            log("Selected text copied to clipboard: $cleanText");
          } else {
            log("No text selected.");
          }
        } catch (e) {
          log("Error retrieving selected text: $e");
        }
      } else if (isi.startsWith('paste')) {

        ClipboardData? data = await (Clipboard.getData(Clipboard.kTextPlain));

        if (data != null) {
          String txtIsi = data.text!
              .replaceAll("'", '\\"')
              .replaceAll('"', '\\"')
              .replaceAll('[', '\\[')
              .replaceAll(']', '\\]')
              .replaceAll('\n', '<br/>')
              .replaceAll('\n\n', '<br/>')
              .replaceAll('\r', ' ')
              .replaceAll('\r\n', ' ');

          String jsCode = """
                              var editor = document.querySelector('.note-editable');
                              if (editor) {
                              document.execCommand('insertHTML', false, '$txtIsi');
                              } else {
                              console.log("Editor not found.");
                              }
                          """;

              try {
                if (txtIsi.isNotEmpty) {
                  await _webViewController!.runJavaScript(jsCode);
                } else {
                  log("No content to paste.");
                }
                } 
                catch (e) {
                   log("Error running JavaScript: $e");
                 }
               }
              } 
              else if (isi.startsWith('cut')) {
              const cutAndPasteScript = '''
                  function cutThenPasteText() {
                  var selection = window.getSelection();
                  if (selection.rangeCount > 0) {
                  document.execCommand('cut'); // First, cut the selected text
                  setTimeout(function() {
                  document.execCommand('paste'); // Then, paste it after a short delay
                  }, 100); // Delay to ensure cut is complete before pasting
                  }
                  }
                  cutThenPasteText();
                  ''';


        _webViewController!.runJavaScript(cutAndPasteScript);
        } 
        else {
        if (isi.isEmpty ||
            isi == '<p></p>' ||
            isi == '<p><br></p>' ||
            isi == '<p><br/></p>') {
          isi = '';
        }
        setState(() {
          text = isi;
        });
        if (widget.returnContent != null) {
          widget.returnContent!(text);
        }
      }
    });
    _webViewController!
        .setNavigationDelegate(NavigationDelegate(onPageFinished: (String url) {
      if (widget.hint != null) {
        setHint(widget.hint);
      } else {
        setHint('');
      }

      setFullContainer();
      if (widget.value != null) {
        setText(widget.value!);
      }

      _webViewController?.runJavaScript('''
          document.addEventListener('contextmenu', (event) => event.preventDefault());
          const style = document.createElement('style');
          style.innerHTML = `
          ::selection { background: rgba(211, 211, 211, 0.3); } /* Optional styling for selected text */
          ::-moz-selection { background: rgba(211, 211, 211, 0.3); }

          /* Hide copy/paste menu */
          .context-menu, ::-webkit-selection-menu { display: none; }
          `;
          document.head.appendChild(style);
          ''');

      _webViewController?.runJavaScript('''
          document.head.insertAdjacentHTML('beforeend', `
          <style>
          .note-editable ul,
          .note-editable ol {
          margin-left: 0; /* Adjust as needed */
          padding-left: 20px; /* Adjust as needed */
          }
          </style>
          `);
          ''');
      }));

    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(_page));
    _webViewController!
        .loadRequest(Uri.parse('data:text/html;base64,$contentBase64'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogContext = context; 
  }

  @override
  void dispose() {
    if (_webViewController != null) {
      _webViewController = null;
    }
    super.dispose();
  }

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? MediaQuery.of(context).size.height,
      decoration: widget.decoration ??
          BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: const Color(0xffececec), width: 1),
          ),
      child: Column(
        children: <Widget>[
          Expanded(
              child: WebViewWidget(
            key: _mapKey,
            controller: _webViewController!,
            gestureRecognizers: {
              Factory(() => VerticalDragGestureRecognizer()),
            },
          )),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    showDialog(
      context: _dialogContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Insert Link'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Link Text'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Insert'),
              onPressed: () {
                String linkText = textController.text;
                String url = urlController.text;

                if (linkText.isNotEmpty && url.isNotEmpty) {
                  String linkHtml = '<a href="$url">$linkText</a>';
                  _insertHtml(linkHtml);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _insertHtml(String html) {
    String jsCode = """
          var editor = document.querySelector('.note-editable');
          if (editor) {
          document.execCommand('insertHTML', false, '$html');
          } else {
          console.log("Editor not found.");
          }
          """;
    _webViewController!.runJavaScript(jsCode);
  }

  /// Call [getText] to get current value from summernote form
  Future<String> getText() async {
    await _webViewController?.runJavaScript(
      'setTimeout(function(){GetTextSummernote.postMessage(document.'
      'getElementsByClassName(\'note-editable\')[0].innerHTML)}, 0);',
    );
    return text;
  }

  /// Call [setText] to set current value in summernote form
  Future<void> setText(String v) async {
    String txtIsi = v
        .replaceAll("'", '\\"')
        .replaceAll('"', '\\"')
        .replaceAll('[', '\\[')
        .replaceAll(']', '\\]')
        .replaceAll('\n', '<br/>')
        .replaceAll('\n\n', '<br/>')
        .replaceAll('\r', ' ')
        .replaceAll('\r\n', ' ');
    String txt =
        'document.getElementsByClassName(\'note-editable\')[0].innerHTML'
        ' = \'$txtIsi\';';
    _webViewController!.runJavaScript(txt);
  }

  /// [setFullContainer] to set full summernote form
  void setFullContainer() {
    _webViewController!
        .runJavaScript('\$("#summernote").summernote("fullscreen.toggle");');
  }

  /// [setFocus] to focus summernote form
  void setFocus() {
    _webViewController!.runJavaScript("\$('#summernote').summernote('focus');");
  }

  /// [setEmpty] called to reset summmernote form
  void setEmpty() {
    _webViewController!.runJavaScript("\$('#summernote').summernote('reset');");
  }

  /// [setHint] to give placeholder
  void setHint(String? text) {
    String hint = '\$(".note-placeholder").html("$text");';
    _webViewController!.runJavaScript('setTimeout(function(){$hint}, 0);');
  }

  /// [widgetIcon] to simplify create a button icon with text
  Widget widgetIcon(IconData icon, String title, {Function? onTap}) {
    return InkWell(
      onTap: onTap as void Function()?,
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: Colors.black38,
            size: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w400),
            ),
          )
        ],
      ),
    );
  }

  /// [_initPage] to initial summernote form
  String _initPage(String? customToolbar) {
    String toolbar;
    if (customToolbar == null) {
      toolbar = _defaultToolbar;
    } else {
      toolbar = customToolbar;
    }
  
    return '''
          <!DOCTYPE html>
          <html lang="en">
          <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
          <title>Summernote</title>
          <style> .note-dropdown-menu { max-height: 150px; } </style>
          <script src="https://code.jquery.com/jquery-3.5.1.min.js" crossorigin="anonymous"></script>
          <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>

          <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
          <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>

          <link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-bs4.min.css" rel="stylesheet"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css">
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
          <style>
          body, p, div {
          line-height: 1.6 !important; /* Override line height */
          margin: 0; /* Remove extra margins */
          padding: 0;
          }
          .custom-link-button {
          display: flex;
          align-items: center;
          }
          .custom-link-button i {
          margin-right: 4px;
          padding: 4px;
          }

          #summernote {

          }
          </style>
          <script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-bs4.min.js"></script>
          </head>
          <body>

          <div id="summernote" contenteditable="true" spellcheck="false" autocorrect="off" autocapitalize="off"></div>
          <script type="text/javascript">
          \$(this).css({
          'background-color': '#D3BCFD !important', // Force the style
          'color': 'white !important'
          });
          \$("#summernote").summernote({
                fontSizes: ['11', '12', '13', '14'],
                lineHeights: ['0.3'],
                placeholder: 'Your text here...',
                tabsize: 2,
                toolbar: $toolbar,
                popover: {},
                callbacks: {
                onInit: function() {
                  \$(this).attr('spellcheck', 'false').attr('autocomplete', 'off');
                  \$('.note-editable').attr('spellcheck', 'false'); // Disable spellcheck
                  \$('.note-editable').attr('autocomplete', 'off'); // Disable autocomplete
                  \$('.note-btn').on('click', function() {
                      // Manually toggle the active state
                      \$(this).toggleClass('active');
                      \$('.note-btn').not(this).removeClass('active');
                    });
                },

          onChange: function(contents, \$editable) {
          GetTextSummernote.postMessage(contents); // Send updated content to Flutter
          },
          onKeyup: function(e) {
          if (e.keyCode === 32 || e.keyCode === 13) { // Space or Enter key
          e.preventDefault(); // Prevent any default action (like suggestions)
          }
          }
          },
          buttons: {
          customLink: function() {
          var ui = \$.summernote.ui;
          var button = ui.button({
          contents: '<span class="custom-link-button"><i class="fa-solid fa-link"></i></span>',
          tooltip: 'Insert a link',
          click: function () {
          // Prompt for the link URL
          GetTextSummernote.postMessage('_showLinkDialog');

          }
          });
          return button.render();
          },
          customCopy: function() {
          var ui = \$.summernote.ui;
          var button = ui.button({
          contents: '<span class="custom-link-button"><i class="fa-regular fa-copy"></i></span>',
          tooltip: 'Copy',
          click: function () {
          // Prompt for the link URL
          GetTextSummernote.postMessage('copy');

          }
          });
          return button.render();
          },
          customPaste: function() {
          var ui = \$.summernote.ui;
          var button = ui.button({
          contents: '<span class="custom-link-button"><i class="fa-solid fa-paste"></i></span>',
          tooltip: 'Paste',
          click: function () {
          // Prompt for the link URL
          GetTextSummernote.postMessage('paste');

          }
          });
          return button.render();
          },
          customCut: function() {
          var ui = \$.summernote.ui;
          var button = ui.button({
          contents: '<span class="custom-link-button"><i class="fa-solid fa-scissors"></i></span>',
          tooltip: 'Cut',
          click: function () {
          // Prompt for the link URL
          GetTextSummernote.postMessage('cut');

          }
          });
          return button.render();
          },
          }
          });

          \$('.note-btn').on('click', function() {
          console.log("Button clicked"); // Debug: Ensure the click event triggers

          // Remove the selected style from all buttons
          \$('.note-btn').css({
          'background-color': '', // Reset background color for all buttons
          'color': '' // Reset text color for all buttons
          });
          console.log("Styles reset for all buttons"); // Debug: Check if reset worked

          // Check if this button was previously selected
          if (\$(this).data('selected')) {
          // Button was selected, so unselect it
          \$(this).css({
          'background-color': 'white', // Unselected background
          'color': 'black' // Unselected text color
          });
          \$(this).data('selected', false);
          console.log("Button unselected"); // Debug: Check if unselect branch was hit
          } else {
          // Button was not selected, so select it
          \$(this).css({
          'background-color': '#D3BCFD', // Selected background color
          'color': 'white' // Selected text color
          });
          \$(this).data('selected', true);
          console.log("Button selected"); // Debug: Check if select branch was hit
          }
          });
          \$(document).on('click', 'a', function(event) {
          event.preventDefault();
          var link = \$(this).attr('href');
          // You can implement your custom link handling here if needed
          if (link) {
          GetTextSummernote.postMessage(link);
          }
          });
          \$('#summernote').summernote('fontSize', 13);
          </script>
          </body>
          </html>
          ''';
  }

  final String _defaultToolbar = """
      [
      ['style', ['bold', 'italic', 'underline', 'clear']],
      ['font', ['strikethrough', 'superscript', 'subscript']],
      ['font', ['fontsize', 'fontname']],
      ['color', ['forecolor', 'backcolor']],
      ['para', ['ul', 'ol', 'paragraph']],
      ['height', ['height']],
      ['view', ['fullscreen']]
      ]
      """;

  void _navigateToWebView(String url) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(url);
    }
  }
}
