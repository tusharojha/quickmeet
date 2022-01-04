import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final bool selected;
  final bool disabled;
  final String text;
  final Function onPressed;
  final double? width;

  const CustomButton(
      {Key? key,
      this.disabled = false,
      this.width,
      required this.text,
      required this.selected,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onPressed(),
      child: Container(
        width: width,
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.teal,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: selected ? Colors.white : null,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
