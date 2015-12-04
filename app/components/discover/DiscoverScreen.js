import React, {
  StyleSheet,
  View,
  Text,
} from 'react-native';

import { connect } from 'react-redux/native';
import { SCREEN_TODAY } from '../../constants';

class DiscoverScreen extends React.Component {

  static id = SCREEN_TODAY;

  render() {
    return (
      <View style={{ paddingTop: 100 }}>
        <Text>Discover Screen!</Text>
      </View>
    )
  }
}

function mapStateToProps(state) {
  return {}
}

export default connect(mapStateToProps)(DiscoverScreen)
