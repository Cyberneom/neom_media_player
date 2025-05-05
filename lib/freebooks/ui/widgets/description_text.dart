import 'package:flutter/material.dart';

class DescriptionTextWidget extends StatefulWidget {
  final String text;

  const DescriptionTextWidget({super.key, required this.text});

  @override
  DescriptionTextWidgetState createState() => DescriptionTextWidgetState();
}

class DescriptionTextWidgetState extends State<DescriptionTextWidget> {
  late String firstHalf;
  late String secondHalf;

  bool flag = true;

  @override
  void initState() {
    super.initState();

    if (widget.text.length > 300) {
      firstHalf = widget.text.substring(0, 300);
      secondHalf = widget.text.substring(300, widget.text.length);
    } else {
      firstHalf = widget.text;
      secondHalf = '';
    }
  }

  @override
  Widget build(BuildContext context) {

    String description = secondHalf.isEmpty ? (flag ? (firstHalf) : (firstHalf + secondHalf)) : (flag ? ('$firstHalf...') : (firstHalf + secondHalf));


    // description = secondHalf.isEmpty ? description.replaceAll(r'\n', '\n').replaceAll(r'\r', '').replaceAll(r"\'", "'")
    //     : description.replaceAll(r'\n', '\n\n').replaceAll(r'\r', '').replaceAll(r"\'", "'").replaceAll(r'\\n\\n', '');

    description = description.replaceAll(r'\\n\\n', '\n\n').replaceAll(r'\\n', '\n').replaceAll(r'\r', '');

    return Container(
      child: secondHalf.isEmpty ? Text(description,
        style: TextStyle(
          fontSize: 16.0,
          color: Theme.of(context).textTheme.bodySmall!.color,
        ),
        textAlign: TextAlign.justify,
      ) : Column(
        children: <Widget>[
          Text(description,
            style: TextStyle(
              fontSize: 16.0,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
            textAlign: TextAlign.justify,
          ),
          InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  flag ? 'Mostrar más' : 'Mostrar menos',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                flag = !flag;
              });
              },
          ),
        ],
      ),
    );
  }
}
