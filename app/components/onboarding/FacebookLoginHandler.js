const logger = new (require('../../../modules/Logger'))('FacebookLoginHandler');

class FacebookLoginHandler {

  constructor(ddp) {
    this.ddp = ddp;
  }

  onLogin(accessTokenString, dispatch) {
    return this.ddp.loginWithFacebook(accessTokenString)
    .then((result) => {
      dispatch({
        type: 'LOGIN_FROM_FB',
      })

      return Promise.resolve(result);
    })
    .catch(err => {
      logger.error(err);
    })
  }
}

module.exports = FacebookLoginHandler;
