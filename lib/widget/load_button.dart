import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadButton extends StatefulWidget {
  final IconData iconData;
  final String text;
  final AsyncCallback onPressed;
  final LoadResultController? loadResultController;

  const LoadButton(
      {super.key,
      required this.iconData,
      required this.text,
      required this.onPressed,
      this.loadResultController});

  @override
  State<StatefulWidget> createState() => LoadButtonState();
}

class LoadResultController {
  final _loadResult = ValueNotifier('');

  void setResult(String? result) {
    _loadResult.value = result ?? '';
  }
}

class LoadButtonState extends State<LoadButton> {
  final _isLoading = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            if (_isLoading.value) {
              return;
            }

            _isLoading.value = true;
            widget.loadResultController?.setResult('');

            await widget.onPressed();

            _isLoading.value = false;
          },
          icon: ValueListenableBuilder(
            valueListenable: _isLoading,
            builder: (context, value, child) {
              return value ? child! : Icon(widget.iconData);
            },
            child: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2.0),
              child: const CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            ),
          ),
          label: Text(widget.text),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: ValueListenableBuilder(
            valueListenable:
                widget.loadResultController?._loadResult ?? ValueNotifier(''),
            builder: (context, value, child) {
              return Text(value);
            },
          ),
        ),
      ],
    );
  }
}
