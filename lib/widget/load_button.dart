import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadButton extends StatelessWidget {
  final IconData iconData;
  final String text;
  final AsyncCallback onPressed;
  final LoadResultController? loadResultController;
  final _isLoading = ValueNotifier(false);

  LoadButton(
      {super.key,
      required this.iconData,
      required this.text,
      required this.onPressed,
      this.loadResultController});

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
            loadResultController?.setResult('');

            await onPressed();

            _isLoading.value = false;
          },
          icon: ValueListenableBuilder(
            valueListenable: _isLoading,
            builder: (context, value, child) {
              return value ? child! : Icon(iconData);
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
          label: Text(text),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: ValueListenableBuilder(
            valueListenable:
                loadResultController?._loadResult ?? ValueNotifier(''),
            builder: (context, value, child) {
              return Text(value);
            },
          ),
        ),
      ],
    );
  }
}

class LoadResultController {
  final _loadResult = ValueNotifier('');

  void setResult(String? result) {
    _loadResult.value = result ?? '';
  }
}
