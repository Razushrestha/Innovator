import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/chatroom/helper.dart';
import 'package:lottie/lottie.dart';

import '../main.dart';

class Forgot_PWD extends StatefulWidget {
  const Forgot_PWD({super.key});

  @override
  State<Forgot_PWD> createState() => _Forgot_PWDState();
}

class _Forgot_PWDState extends State<Forgot_PWD> {
  TextEditingController email = TextEditingController();

  reset() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
    Dialogs.showSnackbar(
        context, 'An Verification Link Has Been Sent. Please Check Your Email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2.0,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(76, 175, 80, 1),
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                  bottomLeft: Radius.circular(70)),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: mq.height * 0.01),
              child: Center(
                child: Lottie.asset('animation/Forgotpwd.json',
                    width: mq.width * .95),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ElevatedButton(
                    //     onPressed: () {
                    //       Navigator.push(context,
                    //           MaterialPageRoute(builder: (_) => Phoneauth()));
                    //     },
                    //     child: Text('Phone number')),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                          hintText: 'Enter Email',
                          suffixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          labelText: 'Email'),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: (() => reset()),
                      label: Text(
                        'Get Verification',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          iconColor: Colors.white),
                      icon: Icon(Icons.verified),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: Text(
                        'Back',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          iconColor: Colors.white),
                      icon: Icon(Icons.arrow_back),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
