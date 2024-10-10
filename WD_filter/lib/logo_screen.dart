import 'package:flutter/material.dart';


class LogoScreen extends StatelessWidget {
  const LogoScreen({super.key});

  @override
  Widget build(context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/quiz-logo.png',
              width: 300,
              color: const Color.fromARGB(150, 255, 255, 255),
            ),
            /* Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/quiz-logo.png',
                width: 300,
              ),
            ), */
            const SizedBox(
              height: 80,
            ),
            const Text(
              'Learn Flutter the fun way',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            OutlinedButton.icon(
                onPressed: () {

                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.arrow_right_alt),
                label: const Text('Star Quiz'))
          ],
        ),
      ),
    );
  }
}
