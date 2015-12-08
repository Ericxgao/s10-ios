import React, {
  Text,
  View,
  PropTypes,
  StyleSheet,
} from 'react-native';

import { connect } from 'react-redux/native';
import { SCREEN_CONVERSATION_LIST } from '../../constants';
import Screen from '../Screen';

// styles
import { SHEET } from '../../CommonStyles';

// display components
import emptyStateContainer from '../lib/emptyStateContainer';

const logger = new (require('../../../modules/Logger'))('ConversationListView')

const TSConversationListView = React.requireNativeComponent(
  'TSConversationListView', ConversationListView);

function mapStateToProps(state) {
  return {
    layer: state.layer,
    me: state.me,
  }
}

class ConversationListView extends React.Component {

  static id = SCREEN_CONVERSATION_LIST;
  static propTypes = {
    me: PropTypes.object.isRequired,
  }

  render() {
    logger.debug(`rendering conversation list with currentuser=${JSON.stringify(this.props.me)}`)

    // verbose but more readable IMO
    if (this.props.layer.allConversationCount > 0) {
      return (
        <View style={[SHEET.container]}>
          <TSConversationListView currentUser={this.props.me} {...this.props} />
        </View>
      )
    }

    return emptyStateContainer(
      require('../img/message.png'),
      'Your conversations will be here :)',
    );
  }
}

export default connect(mapStateToProps)(ConversationListView)
