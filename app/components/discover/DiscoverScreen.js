import React, {
  Dimensions,
  View,
  ScrollView,
  Text,
  Image,
  TouchableHighlight,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';

import { connect } from 'react-redux/native';

import Screen from '../Screen';
import iconTextRow from '../lib/iconTextRow';
import HeaderBanner from '../lib/HeaderBanner';
import { Card } from '../lib/Card';
import Loader from '../lib/Loader';
import { SCREEN_TODAY } from '../../constants';
import { SHEET, COLORS } from '../../CommonStyles';

const logger = new (require('../../../modules/Logger'))('DiscoverScreen');
const { width, height } = Dimensions.get('window');

function mapStateToProps(state) {
  return {
    candidate: state.candidate,
  }
}

class DiscoverScreen extends Screen {

  static id = SCREEN_TODAY;
  static leftButton = () => Screen.generateButton(null, null);
  static rightButton = (route, router) => {
    return Screen.generateButton('History', router.toHistory.bind(router), { isLeft: false });
  }
  static title = () => Screen.generateTitleBar('Today');

  render() {
    const candidate = this.props.candidate;

    if (!candidate) {
      return <Loader />;
    }

    const { coverUrl, connectedProfiles, avatarUrl, major, hometown,
      shortDisplayName } = candidate.user;

    let serviceIcons = [<Image
      key="ubc"
      source={require('../img/ic-ubc.png')}
      style={[SHEET.smallIcon, styles.serviceIcon]} />];
    serviceIcons = serviceIcons.concat(connectedProfiles.map((profile) => {
      return <Image key={profile.id} style={[SHEET.smallIcon, styles.serviceIcon]}
          source={{ uri: profile.icon.url }} />
    }));

    return (
      <View style={SHEET.container}>
        <View style={styles.background}>
          <Image
            source={require('../img/bg-compass.png')}
            style={{ width: width / 1.5, height: width / 1.5, resizeMode: 'contain' }} />
          <Text style={[styles.backgroundQuoteText, SHEET.baseText]}>
            Every good friend was once a stranger.
          </Text>
        </View>
        <View style={{flex: 1, paddingTop: 74}}>
          <TouchableHighlight
              onPress={() => this.props.onViewProfile({ user: candidate.user })}
              style={{ flex: 1}}
              underlayColor={'transparent'}>

            <View style={{flex: 1}}>
              <Card style={[{flex: 1, marginBottom: 10}, SHEET.innerContainer]}
                cardOverride={[{ flex: 1, padding: 0 }]}>

                <View style={{ height: height / 2.5 }}>
                  <HeaderBanner url={coverUrl} height={height / 2.5}>
                    <View style={styles.header}>
                      <Image source={{ uri: avatarUrl }} style={styles.avatar} />
                    </View>

                    <View style={styles.bottomInfo}>
                      <View style={styles.userInfo}>
                        <Text style={[styles.userNameText, SHEET.baseText]}>
                        { shortDisplayName }
                      </Text>
                      </View>
                      <View style={{ right: 10 }}>
                        <View style={{ flex: 1 }}></View>
                        <View style={styles.serviceInfo}>
                          { serviceIcons }
                        </View>
                      </View>
                    </View>
                  </HeaderBanner>
                </View>


                <View style={[styles.infoSection, SHEET.innerContainer]}>
                  {iconTextRow(require('../img/ic-mortar.png'), major)}
                  {iconTextRow(require('../img/ic-house.png'), hometown)}
                </View>

                <View style={[{ marginHorizontal: 10 }, SHEET.separator]} />

                <View style={[{ flex: 1}, styles.infoSection, SHEET.innerContainer]}>
                  <Text style={[SHEET.baseText]}>
                    { candidate.reason }
                  </Text>
                </View>


              </Card>
            </View>
            </TouchableHighlight>
          </View>

      </View>
    )
  }
}

let avatarRadius = height / 4.5;

var styles = StyleSheet.create({
  background: {
    position: 'absolute',
    left: 0,
    top: 0,
    width: width,
    height: height,
    alignItems: 'center',
    justifyContent: 'center',
  },
  backgroundQuoteText: {
    paddingTop: 15,
    fontSize: 20,
    color: COLORS.attributes,
    textAlign: 'center',
    marginHorizontal: width / 32,
  },
  avatar: {
    borderWidth: 2.5,
    borderColor: 'white',
    borderRadius: avatarRadius / 2,
    height: avatarRadius,
    width: avatarRadius,
  },
  header: {
    position: 'absolute',
    backgroundColor: 'rgba(0,0,0,0)',
    top: 0,
    left: 0,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    width: width,
    height: height / 2.5,
  },
  userInfo: {
    flex: 1,
  },
  serviceInfo: {
    height: 32,
    justifyContent: 'center',
    flexDirection: 'row',
  },
  bottomInfo: {
    position: 'absolute',
    bottom: 0,
    width: width,
    flexDirection: 'row',
    backgroundColor: 'transparent',
    paddingHorizontal: width / 32,
    paddingVertical: 5,
  },
  userNameText: {
    color: 'white',
    fontSize: 24,
  },
  infoSection: {
    paddingHorizontal: width / 64,
    paddingVertical: 10,
  },
  messageButton: {
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
    marginHorizontal: width / 32,
    backgroundColor: COLORS.button,
    marginBottom: 10,
    borderRadius : 3,
  },
  messageButtonText: {
    paddingLeft: width / 64,
    fontSize: 18,
    color: COLORS.white,
  },
  headerText: {
    color: COLORS.white,
    fontSize: 24
  },
  serviceIcon: {
    marginRight: 5,
  },
});

export default connect(mapStateToProps)(DiscoverScreen)
