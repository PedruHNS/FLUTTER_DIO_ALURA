import 'package:flutter/material.dart';

class DialogWidget extends StatelessWidget {
  final String title;
  final String content;
  final void Function()? onPressed;

  const DialogWidget({
    super.key,
    required this.title,
    required this.content,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar')),
        TextButton(onPressed: onPressed, child: const Text('confirmar'))
      ],
    );
  }
}
