let React = require('react-native');

let {
  StyleSheet
} = React;

let BACKGROUND_COLOR = '#e0e0e0';
let TAYLR_COLOR = '#64369C';
let EMPTY_HASHTAG = '#cccccc';
let SUBTITLE_COLOR = '#666666';

exports.COLORS = {
  background: BACKGROUND_COLOR,
  taylr: TAYLR_COLOR,
  emptyHashtag: EMPTY_HASHTAG,
  subtitle: SUBTITLE_COLOR,
  white: 'white'
};

exports.SHEET = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: BACKGROUND_COLOR,
  },
  baseText: {
    fontFamily: 'Cabin-Regular'
  },
  row: {
    flex: 1,
    alignItems: 'center',
    flexDirection: 'row',
  },
  innerContainer: {
    marginHorizontal: 8,
  },
  navTop: {
    paddingTop: 64,
  },
  bottomTile: {
    paddingBottom: 64,
  },
  subTitle: {
    color: SUBTITLE_COLOR,
    fontSize: 14
  },
  smallHeading: {
    paddingVertical: 4,
  },
  smallIcon: {
    width: 24,
    height: 24,
    resizeMode: 'contain',
  },
  smallIconCircle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    resizeMode: 'contain',
  },
  icon: {
    width: 32,
    height: 32,
    resizeMode: 'contain',
  },
  iconCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    resizeMode: 'contain',
  },
  bigIconCircle: {
    width: 128,
    height: 128,
    borderRadius: 64,
  },
  separator: {
    backgroundColor: BACKGROUND_COLOR,
    height: 1
  },
});