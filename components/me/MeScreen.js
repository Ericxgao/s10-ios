let React = require('react-native');
let {
  AppRegistry,
  View,
  ScrollView,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
} = React;

let BridgeManager = require('../../modules/BridgeManager');

let Dimensions = require('Dimensions');
let { width, height } = Dimensions.get('window');

let SHEET = require('../CommonStyles').SHEET;
let COLORS = require('../CommonStyles').COLORS;
let NetworkComponent = require('./NetworkComponent')
let MoreComponent = require('./MoreComponent');
let SectionTitle = require('../lib/SectionTitle');
let HeaderBanner = require('../lib/HeaderBanner');
let HashtagCategory = require('../lib/HashtagCategory');
let Loader = require("../lib/Loader");
let Button = require('react-native-button');

class MeButton extends React.Component {
  render() {
    return(
      <View style={[buttonStyles.container, this.props.style]}>
        <Button
          onPress={this.props.onPress}>
            <View style={[buttonStyles.button, buttonStyles.buttonContainer]} />
            <View style={buttonStyles.button}>
              <Text style={[buttonStyles.buttonText, SHEET.baseText]}>
                { this.props.text }
              </Text>
            </View>
        </Button> 
      </View>
    ) 
  }
}
var buttonStyles = StyleSheet.create({
  container: {
    borderWidth: 1,
    borderColor: 'white',
    alignItems: 'center',
    borderRadius: 2,
  },
  buttonContainer: {
    position:'absolute',
    backgroundColor: 'black',
    opacity: 0.6,
  },
  button: {
    width: 5 * width / 16,
    height: height / 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    fontSize:16,
    color:'white',
  }
});

class MeHeader extends React.Component {

  render() {
    let me = this.props.me;

    var serviceIcons = [<Image key="ubc" source={require('../img/ic-ubc.png')}
      style={[SHEET.smallIcon, styles.serviceIcon]} />];

    if (me.connectedProfiles) {
      let moreIcons = me.connectedProfiles.map((profile) => {
        return <Image key={profile.id} style={[SHEET.smallIcon, styles.serviceIcon]}
            source={{ uri: profile.icon.url }} />
      });
      serviceIcons = serviceIcons.concat(moreIcons);
    }

    return (
      <View style={styles.meHeader}>
        <Image style={styles.avatar} source={{ uri: me.avatarUrl}} />
        <View style={styles.headerContent}>
          <Text style={[styles.headerText, SHEET.baseText]}>
            {me.shortDisplayName}
          </Text> 
          <View style={styles.headerContentLineItem}>
            { serviceIcons }
          </View>
          <View style={styles.headerContentLineItem}>
            <MeButton text={'View'} onPress={() => {
               this.props.parentNavigator.push({
                id: 'viewprofile',
                me: me,
              })
            }} />
            <MeButton style={{ left: width / 32 }} text={'Edit'} onPress={() => {
              this.props.navigator.push({
                id: 'edit',
                title: 'Edit Profile',
                me: me,
              })}} />
          </View>
        </View>
      </View>
    )
  }
}

class Me extends React.Component {

  render() {
    let ddp = this.props.ddp;
    let me = this.props.me;

    if (!me) {
      return <Loader />
    }

    return (
      <View style={SHEET.container}>
        <ScrollView 
          showsVerticalScrollIndicator={false}
          style={[{ top: 64 }]}>
          
          <TouchableOpacity onPress={() => {
              this.props.parentNavigator.push({
                id: 'viewprofile',
                title: 'Profile',
                me: me,
              })
            }}>
            <HeaderBanner url={me.coverUrl} height={ height / 4 }>
              <MeHeader
                parentNavigator={this.props.parentNavigator}
                navigator={this.props.navigator}
                ddp={ddp} me={me} />
            </HeaderBanner>
          </TouchableOpacity>

          <View style={SHEET.innerContainer}>
            <SectionTitle title={'MY SCHOOL'} />
            <NetworkComponent navigator={this.props.navigator} ddp={ddp} />

            <SectionTitle title={'MY HASHTAGS'} />
            <HashtagCategory navigator={this.props.navigator}
              categories={this.props.categories}
              myTags={this.props.myTags}
              ddp={this.ddp} />

            <SectionTitle title={'MORE'} />
            <MoreComponent 
              navigator={this.props.navigator}
              onLogout={this.props.onLogout}
              ddp={this.props.ddp} />
          </View>

          <View style={styles.versionTextContainer}>
          <Text style={[styles.versionText, SHEET.innerContainer, SHEET.baseText]}>
             Version { BridgeManager.version() }
          </Text>
          </View>
          <View style={SHEET.bottomTile} />
        </ScrollView>
      </View>
    )
  }
}

var styles = StyleSheet.create({
  avatar: {
    borderWidth: 2.5,
    borderColor: 'white',
    borderRadius: width / 8,
    height: width / 4,
    width: width / 4,
  },
  meHeader: {
    position: 'absolute',
    backgroundColor: 'rgba(0,0,0,0)',
    top: 0,
    left: 0,
    alignItems: 'center',
    flexDirection: 'row',
    height: height / 4,
    marginHorizontal: width / 32,
  },
  headerContent: {
    flexDirection: 'column',
    left: width / 32,
  },
  headerContentLineItem: {
    flex: 1,
    flexDirection: 'row',
    marginTop: 10,
  },
  headerText: {
    color: 'white',
    fontSize: 24
  },
  serviceIcon: {
    marginRight: 5,
  },
  versionTextContainer: {
    flex: 1,
    height: 64, 
    alignItems: 'center',
    justifyContent: 'center',
  },
  versionText: {
    textAlign: 'center',
    fontSize: 16,
    color: COLORS.emptyHashtag,
  },
});

module.exports = Me;