let React = require('react-native');
let TaylrAPI = require('react-native').NativeModules.TaylrAPI;

let {
  AppRegistry,
  View,
  ScrollView,
  Text,
  TextInput,
  Image,
  Navigator,
  TouchableHighlight,
  StyleSheet,
  AlertIOS,
} = React;

let SHEET = require('../CommonStyles').SHEET;
let TappableCard = require('../lib/Card').TappableCard;
let Card = require('../lib/Card').Card;
let EditMyPhotoHeader = require('../lib/EditMyPhotoHeader');
let SectionTitle = require('../lib/SectionTitle');
let ServiceTile = require('../lib/ServiceTile');
let ProfileEditCard = require('../lib/ProfileEditCard');
let LinkServiceCard = require('../lib/LinkServiceCard');
let AlertOnPressButton = require('../lib/AlertOnPressButton');

class MeEdit extends React.Component {

  render() {
    let me = this.props.me;
    let integrations = this.props.integrations;

    if (!me || !integrations){
      return (<Text>Loading ...</Text>);
    } 

    return (
      <View style={SHEET.container}>
        <ScrollView style={[SHEET.navTop]}>
          <EditMyPhotoHeader me={me} height={200} />

          <View style={SHEET.innerContainer}>
            <SectionTitle title={'SERVICES'} />
            <LinkServiceCard navigator={this.props.navigator} services={integrations} />

            <SectionTitle title={'MY INFO'} />
            <View style={SHEET.separator} />
            <ProfileEditCard me={me} ddp={this.props.ddp} />

          </View>
          <View style={SHEET.bottomTile} />
        </ScrollView>
      </View>
    )
  }
}

module.exports = MeEdit;