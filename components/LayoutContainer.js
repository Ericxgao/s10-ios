let React = require('react-native');

let {
  AppRegistry,
  AlertIOS,
  NativeAppEventEmitter,
  View,
  TabBarIOS,
} = React;

let Analytics = require('../modules/Analytics');
let BridgeManager = require('../modules/BridgeManager');

let OnboardingNavigator = require('./onboarding/OnboardingNavigator');
let RootNavigator = require('./RootNavigator');
let Loader = require('./lib/Loader');

let TSDDPClient = require('../lib/ddpclient');
let TSLayerService = React.NativeModules.TSLayerService;

let SHEET = require('./CommonStyles').SHEET;
let Logger = require('../lib/Logger');

let Digits = require('react-native-fabric-digits');
let { DigitsAuthenticateManager } = Digits;

let FBSDKLogin = require('react-native-fbsdklogin');
let { FBSDKLoginManager } = FBSDKLogin;

class LayoutContainer extends React.Component {

  constructor(props: {}) {
    super(props);
    this.ddp = new TSDDPClient(props.wsurl);
    this.state = {
      needsOnboarding: true,
      modalVisible: false,
      currentTab: 'chats',
    }

    this.logger = new Logger(this);
  }

  formatUser(user) {
    if (!user) {
      return user;
    }

    let {firstName, lastName, gradYear} = user;

    const generateDisplayName = (length) => {
      let displayName = firstName;
      if (lastName && displayName.length + lastName.length < length) {
        displayName += ` ${lastName}`;
      }

      if (gradYear && displayName.length + gradYear.length < length) {
        displayName += ` ${gradYear}`;
      }
      return displayName;
    }

    user.shortDisplayName = generateDisplayName(20);
    user.longDisplayName = generateDisplayName(30);
    return user;
  }

  async onLogout() {
    await TSLayerService.deauthenticateAsync();
    DigitsAuthenticateManager.logout();
    FBSDKLoginManager.logOut();

    await this.ddp.logout()
    await BridgeManager.setDefaultAccount(null)
    this.setState({ loggedIn: false });
  }

  /** 
   * account: { userID, resumeToken }
   */
  async onLogin(account) {
    const ddp = this.ddp;
    await BridgeManager.setDefaultAccount(account)

    this.setState({ loggedIn: true });
    this.__layerLogin()

    this.ddp.subscribe({ pubName: 'settings' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.settings) {
          return ddp.collections.settings.find({});
        }
      }).subscribe(settings => {
        indexedSettings =  {};
        settings.forEach((setting) => {
          indexedSettings[setting._id] = setting;
        });

        this.setState({ settings: indexedSettings });

        if (indexedSettings.accountStatus) {
          this.setState ({
            isActive: indexedSettings.accountStatus.value == 'active'
          })
        }

        if (indexedSettings.CWLRequired && indexedSettings.tfCWLRequired) {
          let isCWLRequired = BridgeManager.isRunningTestFlightBeta() ? 
              indexedSettings.tfCWLRequired.value :
              indexedSettings.CWLRequired.value;
          this.setState({ isCWLRequired: isCWLRequired });
        }
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) })

    this.ddp.subscribe({ pubName: 'me' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.users) {
          return ddp.collections.users.findOne({ _id: ddp.currentUserId });
        }
      }).subscribe(currentUser => {
        if (currentUser) {
          Analytics.identify(currentUser._id) 
          this.setState({ me: this.formatUser(currentUser) });
        }
      });

      ddp.collections.observe(() => {
        if (ddp.collections.users) {
          return ddp.collections.users.find({});
        }
      }).subscribe(users => {
        if (users) {
          let formattedUsers = users.map(user => {
            return this.formatUser(user);
          })
          this.setState({ users: formattedUsers });
        }
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });

    this.ddp.subscribe({ pubName: 'integrations' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.integrations) {
          return ddp.collections.integrations.find({});
        }
      }).subscribe(integrations=> {
        integrations.sort((one, two) => {
          return one.status == 'linked' ? -1 : 1;
        })
        this.setState({ integrations: integrations });
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });

    this.ddp.subscribe({ pubName: 'hashtag-categories' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.categories) {
          return ddp.collections.categories.find({});
        }
      }).subscribe(categories=> {
        this.setState({ categories: categories });
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });

    this.ddp.subscribe({ pubName: 'my-tags' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.mytags) {
          return ddp.collections.mytags.findOne({});
        }
      }).subscribe(user => {
        if (user && user.tags) {
          user.tags.forEach((tag) => {
            tag.isMine = true;
          })
          this.setState({ myTags: user.tags });
        }
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });

    this.ddp.subscribe({ pubName: 'candidate-discover' })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.candidates) {
          return ddp.collections.candidates.find({});
        }
      }).subscribe(candidates => {
        let activeCandidates = candidates.filter((candidate) => {
          return candidate.type == 'active'
        })

        let historyCandidates = candidates.filter((candidate) => {
          return candidate.type == 'expired'
        })

        if (activeCandidates.length > 0) {
          this.setState({ candidate: activeCandidates[0] })
        }

        this.setState({ history: historyCandidates });
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });

    this.ddp.subscribe({ pubName: 'activities', params:[ddp.currentUserId] })
    .then(() => {
      ddp.collections.observe(() => {
        if (ddp.collections.activities) {
          return ddp.collections.activities.find({ userId: ddp.currentUserId });
        }
      }).subscribe(activities => {
        this.setState({ myActivities: activities });
      });
    })
    .catch(err => { this.logger.error(JSON.stringify(err)) });
  }

  async __layerLogin() {
    NativeAppEventEmitter.addListener('Layer.allConversationsCountUpdate', (count) => {
      this.setState({ numTotalConversations: count })
    }.bind(this))
    try {
      await TSLayerService.connectAsync();
      const isAuthenticated = await TSLayerService.isAuthenticatedAsync();
      if (isAuthenticated) {
        return;
      }
      const nonce = await TSLayerService.requestAuthenticationNonceAsync();
      const sessionId = await this.ddp.call({ methodName: 'layer/auth', params: [nonce]});
      await TSLayerService.authenticateAsync(sessionId);
    } catch (error) {
      this.logger.error(`Unable to complete layer flow: ${error.toString()}`)
    }
  }

  async _ddpLogin() {
    let ddp = this.ddp;

    await ddp.initialize()
    const defaultAccount = await BridgeManager.getDefaultAccountAsync()

    if (defaultAccount) {
      const { resumeToken } = defaultAccount;
      let loginResult = await ddp.loginWithToken(resumeToken)

      if (loginResult.token) {
        this.onLogin(defaultAccount);
      } else {
        this.setState({ loggedIn: false });
      }

    } else {
      this.setState({ loggedIn: false });
    }
  }

  reportUser(user) {
    if (user) {
      Analytics.track("User: View Block", { userId: user._id })

      AlertIOS.alert(
        `Report ${user.firstName}?`,
        "",
        [
          {text: 'Cancel', onPress: () => null },
          {text: 'Report', onPress: () => {
            return this.ddp.call({ methodName: 'user/report', params: [user._id, 'Reported'] })
            .then(() => {
              Analytics.track("User: Confirmed Block")
              AlertIOS.alert(`Reported ${user.firstName}`, 
                'Thanks for your input. We will look into this shortly.');
            })
          }},
        ]
      )
    }
  }

  componentWillMount() {
    this._ddpLogin()

    this.setState({
      showMoreOptionsListener: NativeAppEventEmitter.addListener('Profile.showMoreOptions', (userId) => {
        let user = this.ddp.collections.users.findOne({ _id: userId });
        this.reportUser(user)
      }.bind(this)),
    })
  }

  componentWillUnmount() {
    this.state.showMoreOptionsListener.remove()
    this.setState({
      showMoreOptionsListener: null
    })
  }

  render() {
    if (!this.state.loggedIn || !this.state.isActive) {
      return <OnboardingNavigator
        loggedIn={this.state.loggedIn}
        isActive={this.state.isActive}
        integrations={this.state.integrations}
        me={this.state.me} 
        categories={this.state.categories}
        myTags={this.state.myTags}
        onLogin={this.onLogin.bind(this)}
        isCWLRequired={this.state.isCWLRequired}
        ddp={this.ddp} /> 
    }

    return <RootNavigator
      me={this.state.me}
      integrations={this.state.integrations}
      categories={this.state.categories}
      myTags={this.state.myTags}
      loggedIn={this.state.loggedIn}
      reportUser={this.reportUser.bind(this)}
      onLogout={this.onLogout.bind(this)}
      onLogin={this.onLogin.bind(this)}
      candidate={this.state.candidate}
      history={this.state.history}
      users={this.state.users}
      settings={this.state.settings}
      numTotalConversations={this.state.numTotalConversations}
      numUnreadConversations={this.state.numUnreadConversations}
      ddp={this.ddp} />
  }
}

module.exports = LayoutContainer;