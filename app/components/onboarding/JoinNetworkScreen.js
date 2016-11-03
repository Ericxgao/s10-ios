let React = require('react-native');

let {
  AppRegistry,
  View,
  Image,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} = React;

let Dimensions = require('Dimensions');
let { width, height } = Dimensions.get('window');

let Button = require('react-native-button')

let SHEET = require('../../CommonStyles').SHEET;
let COLORS = require('../../CommonStyles').COLORS;
let ProfileEditCard = require('../lib/ProfileEditCard');
let Loader = require('../lib/Loader');

import Router from '../../nav/Routes'
import { connect } from 'react-redux/native';
import { GoogleSignin } from 'react-native-google-signin';

function mapStateToProps(state) {
  return {
    ddp: state.ddp,
  }
}

class JoinNetworkScreen extends React.Component {

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
      if (isValid) {
        const route = Router.instance.getProfileRoute({
          userId: this.props.ddp.currentUserId,
          isEditable: true });
        this.props.navigator.push(route);
      } else {
        this.props.dispatch({
          type: 'INVALID_EMAIL_ERROR',
          title: 'Invalid Email',
          message: 'Sorry, you need a valid email for your university to log in.',
        });
      }
    })
    .catch((err) => {
      console.log('Error signing in', err);
    })
    .done();
  }

  render() {
    return (
      <View style={SHEET.container}>
        <View>
          <Image source={require('../img/bg-sauder.jpg')} style={styles.bgimage} />
        </View>

        <View style={styles.contentContainer}>
          <Text style={[styles.contentText, SHEET.baseText]}>
            Taylr is currently only available to students at UC Berkeley.
          </Text>

          <TouchableOpacity
              style={styles.button}
              onPress={this.onLoginPress.bind(this)}>
            <Image source={require('../img/ic-lock.png')} style={{ height: 15, resizeMode: 'contain' }} />
            <Text style={[styles.buttonText, SHEET.baseText]}>Google Login</Text>
          </TouchableOpacity>
        </View>
        <Text style={[styles.footerText, SHEET.baseText]}>
          We never handle or store your UC Berkeley password. You authenticate directly with CWL
          to verify your association with UC Berkeley and populate your profile.
        </Text>
      </View>
    )
  }
}

var styles = StyleSheet.create({
  bgimage: {
    width: width,
    height: height,
  },
  contentContainer: {
    position: 'absolute',
    top: height / 3,
    backgroundColor: 'transparent',
    width: 7 * width / 8,
    left: width / 16,
  },
  contentText: {
    fontSize: 22,
    color: 'white',
    textAlign: 'center',
    marginBottom: height / 16,
  },
  button: {
    backgroundColor: 'white',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: height / 16,
  },
  buttonText: {
    marginLeft: 5,
    fontSize: 18,
    color: 'black',
  },
  footerText: {
    position: 'absolute',
    bottom: height / 32,
    fontSize: 12,
    color: '#BDBDBD',
    width: 7 * width / 8,
    left: width / 16,
    backgroundColor: 'transparent',
  }
});

export default connect(mapStateToProps)(JoinNetworkScreen)
