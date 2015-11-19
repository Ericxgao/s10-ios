'use strict';

let React = require('react-native');
let ViewControllerManager = React.NativeModules.TSViewController;

let UserSchema = React.PropTypes.shape({
    userId: React.PropTypes.string.isRequired,
    avatarUrl: React.PropTypes.string,
    coverUrl: React.PropTypes.string,
    firstName: React.PropTypes.string,
    lastName: React.PropTypes.string,
    displayName: React.PropTypes.string,
})

class ConversationListView extends React.Component {
  componentDidMount() {
    this.setState({
      routeListener: React.NativeAppEventEmitter.addListener(
        'ViewController.pushRoute',
        (properties) => console.log('Pushing route ', properties)
      )
    });
    ViewControllerManager.componentDidMount(React.findNodeHandle(this))
  }
  componentWillUnmount() {
    ViewControllerManager.componentWillUnmount(React.findNodeHandle(this))
    this.state.routeListener.remove();
  }
  render() {
    return <TSConversationListView {...this.props} />;
  }
}

ConversationListView.propTypes = {
  currentUser: UserSchema,
}

var TSConversationListView = React.requireNativeComponent('TSConversationListView', ConversationListView);

module.exports = ConversationListView

