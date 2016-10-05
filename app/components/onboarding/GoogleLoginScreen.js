import React, {
  PropTypes,
} from 'react-native';

import {GoogleSignin, GoogleSigninButton} from 'react-native-google-signin';


class GoogleLoginScreen extends React.Component {
  componentWillMount() {
    const validEmailDomains = ["berkeley.edu"];
    GoogleSignin.configure({
      iosClientId: '749725548538-toleibucsvarl0r2si0m87ccnkm9vgnk.apps.googleusercontent.com', // only for iOS 
    })
    .then(() => {
      // you can now call currentUserAsync() 
    });

    this.setState({validEmailDomains : validEmailDomains});
  }

  onLoginPress() {
    GoogleSignin.signIn()
    .then((user) => {
      var domain = user.email.replace(/.*@/, "");
      var isValid = this.state.validEmailDomains.includes(domain);
      this.props.onFinishedLogin(isValid);
    })
    .catch((err) => {
      console.log('Error signing in', err);
    })
    .done();
  }

  render() {

    return (
      <GoogleSigninButton
        style={{width: 48, height: 48}}
        size={GoogleSigninButton.Size.Icon}
        color={GoogleSigninButton.Color.Dark}
        onPress={this.onLoginPress.bind(this)}/>
    );
  }
}

module.exports = GoogleLoginScreen;
