import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 1. عنوان الصفحة (أقصى اليمين)
          const Text(
            'dafter',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),

          // 2. شريط البحث
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: CustomTextFormField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'بحث سريع عن منتج، عميل، أو فاتورة...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF6F8F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
