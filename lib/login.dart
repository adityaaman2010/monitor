import 'package:flutter/material.dart';
import 'package:monitor/helper.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static String logo = 'assets/images/logo.png';
  static String title = 'Data Acquision System';
  static String serialNo = 'Serial No.  :VSET030000001';
  static String modelNo = 'Model No.  :VSETAC2000PS';
  String userName = '';
  String passwordValue = '';

  final TextEditingController userId = TextEditingController();
  final TextEditingController password = TextEditingController();

  void logMeIn() {
    if (userName == 'admin' && passwordValue == 'admin@123') {
      Navigator.pushReplacementNamed(context, '/port_config');
    } else {
      Helper.showError(
        context,
        'Invalid Credentials',
        'Username or password is wrong',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    userId.addListener(() {
      setState(() {
        userName = userId.text;
      });
    });
    password.addListener(() {
      setState(() {
        passwordValue = password.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logo,
              fit: BoxFit.cover,
            ),
            Text(
              serialNo,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12.0,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              modelNo,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12.0,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(
              height: 120.0,
            ),
            SizedBox(
              width: 300.0,
              child: Material(
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'Please enter the user id provided',
                    labelText: 'user id *',
                  ),
                  controller: userId,
                ),
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            SizedBox(
              width: 300.0,
              child: Material(
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.key),
                    hintText: 'Please enter the password',
                    labelText: 'password *',
                  ),
                  controller: password,
                  obscureText: true,
                ),
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.orange),
              ),
              onPressed: logMeIn,
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
