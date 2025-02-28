# Html WYSIWYG

Html WYSIWYG package lets you add text field with link , bullets , copy paste options , font size , bold, italic and button customization.

## Installation

1. Add the latest version of package to your pubspec.yaml (and run`dart pub get`):

```yaml
dependencies:
  html_wysiwyg_textfield: ^0.0.1
```

2. Import the package and use it in your Flutter App.

```dart
import 'package:html_wysiwyg_textfield/html_wysiwyg_textfield.dart';
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


# HtmlWysiwygScreen Preview

This screen implements a WYSIWYG HTML editor with a custom toolbar.

## 📜 Code Implementation

<table>
<tr>
<td style="width: 60%; vertical-align: top;">

```dart
class HtmlWysiwygScreen extends StatelessWidget {
  const HtmlWysiwygScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
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
        ],
      ),
    );
  }
}
```

</td> <td style="width: 40%; vertical-align: top; text-align: center;"> 
  <h3>🎨 HtmlWYSIWYGTextField Preview</h3> 
  <img src="https://github.com/user-attachments/assets/ae1bf733-46a0-4ca4-9019-b1a1ebda8224" alt="Editor Preview" style="width: 100%; max-width: 300px; height: auto; object-fit: cover;"> 
</td> 
</tr> 
</table>
