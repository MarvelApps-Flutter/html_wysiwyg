# Html WYSIWYG

Html WYSIWYG package lets you add text field with link , bullets , copy paste options , font size , bold and italic customization.

## Installation

1. Add the latest version of package to your pubspec.yaml (and run`dart pub get`):

```yaml
dependencies:
  html_wysiwyg_text_field: ^0.0.1
```

2. Import the package and use it in your Flutter App.

```dart
import 'package:html_wysiwyg_text_field/html_wysiwyg_text_field.dart';
```

## Example

There are a number of properties that you can modify:

- value
- height
- decoration
- hint
- customToolbar
- returnContent
- onNavigate

<hr>

<table>
<tr>
<td>

```dart
class HtmlWysiwygScreen extends StatelessWidget {
  const HtmlWysiwygScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: 
            HtmlWYSIWYGTextField(
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
                key: _keyEditor,
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
    );
  }
}
```

</td>
<td>
<img  src=""  alt="">
</td>
</tr>
</table>
