import 'package:flutter/material.dart';

class DropdownSelector<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?)? onChanged;
  final String hint;
  final bool isLoading;

  const DropdownSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
          ),
          items: items.map((T item) {
            String displayText;
            if (item is int) {
              displayText = 'Semester $item';
            } else {
              displayText = item.toString();
            }
            return DropdownMenuItem<T>(value: item, child: Text(displayText));
          }).toList(),
        ),
        if (isLoading) const LinearProgressIndicator(),
      ],
    );
  }
}
