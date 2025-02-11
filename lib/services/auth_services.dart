import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

    Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();
  //google sign in
  signInWithGoogle() async {
    //begin interactive google sign in process
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    //obtain auth details from request
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    //create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //let's sign in with credential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
