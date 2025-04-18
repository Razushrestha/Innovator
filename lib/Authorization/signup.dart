import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innovator/chatroom/helper.dart';
import 'package:innovator/main.dart';

class signup extends StatefulWidget {
  const signup({super.key});

  @override
  State<signup> createState() => _signupState();
}

class _signupState extends State<signup> {
  bool _isPasswordVisible = false;

  final Color preciseGreen = Color.fromRGBO(76, 175, 80, 1);

  bool isLogin = true;
  TextEditingController name = TextEditingController();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(primaryColor: preciseGreen),
      child: Scaffold(
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   backgroundColor: Colors.green,
        //   centerTitle: true,
        //   title: Text('SignUp',
        //       style:
        //           TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(76, 175, 80, 1),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  // child: Lottie.asset('animation/loginani.json',
                  //     width: mq.width * .95),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: name,
                            decoration: InputDecoration(
                              labelText: 'Enter Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Enter Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            obscureText: !_isPasswordVisible,
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Enter Password',
                              prefixIcon: Icon(Icons.password),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons
                                          .visibility, // Change icon based on visibility
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,

                            // Make the background color transparent
                            foregroundColor:
                                Colors
                                    .white, // Replace with your desired text color
                            elevation:
                                10, // Replace with your desired elevation
                            shadowColor:
                                Colors
                                    .transparent, // Replace with your desired shadow color
                            minimumSize: Size(
                              100,
                              50,
                            ), // Replace with your desired minimum size
                            maximumSize: Size(
                              200,
                              100,
                            ), // Replace with your desired maximum size
                            padding: EdgeInsets.all(
                              10,
                            ), // Replace with your desired padding
                            side: BorderSide(
                              width: 1,
                              color: Colors.transparent,
                            ), // Replace with your desired border
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ), // Replace with your desired shape
                          ),
                          onPressed: () {
                            FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text,
                                )
                                .then((userCredential) {
                                  // After creating the user, update the user's profile with the name
                                  userCredential.user?.updateProfile(
                                    displayName: name.text,
                                  );

                                  Dialogs.showSnackbar(
                                    context,
                                    'Account Has Successfully Created',
                                  );
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (_) => MainNavigationScreen(
                                  //               user: APIs.me,
                                  //             )));
                                })
                                .onError((error, stackTrace) {
                                  print("Error creating account: $error");
                                });
                            // handle login
                          },
                          label: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              letterSpacing: 1.1,
                            ),
                          ),
                          icon: Icon(Icons.person),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          label: Text(
                            'Back',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          icon: Icon(Icons.arrow_back),
                          style: ElevatedButton.styleFrom(
                            iconColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
