import React, {
  ListView,
  View,
  Text,
} from 'react-native';

import InfiniteScrollView from 'react-native-infinite-scroll-view';
import SearchBar from 'react-native-search-bar';
import Loader from './Loader';

const logger = new (require('../../../modules/Logger'))('AllCoursesListView');

class AllCoursesListView extends React.Component {

  constructor(props = {}) {
    super(props);
    this.courses = {};

    this.state = {
      dataSource: new ListView.DataSource({
        rowHasChanged: (row1, row2) => row1 !== row2,
      }),
      loaded: false,
      canLoadMore: true,
    }
  }

  componentWillMount() {
    this.loadMore()
  }

  loadMore() {
    this.setState({
      isLoadingMore: true
    })

    return this.props.ddp.call({
      methodName: 'courses/get',
      params: [this.state.searchText, this.state.offset]})
    .then(result => {
      result.courses.forEach(course => {
        this.courses[course._id] = course
      })

      let courseValues = Object.keys(this.courses).map(key => this.courses[key])

      if (this.state.searchText) {
        const regex = new RegExp(`^${this.state.searchText}`);
        courseValues = courseValues.filter(course => {
          logger.info(`course=${JSON.stringify(course)}`)
          return regex.exec(course.courseCode) != null
        })
      }

      this.setState({
        dataSource: this.state.dataSource.cloneWithRows(courseValues),
        offset: result.offset,
        canLoadMore: result.canLoadMore,
        isLoadingMore: false
      })
    })
    .catch(err => {
      logger.warning(JSON.stringify(err));
    })
  }

  search(text) {
    this.setState({
      searchText: text,
      offset: 0,
    });
    this.loadMore()
  }

  render() {
    return (
      <View style={this.props.style}>
        <SearchBar
          ref='searchBar'
          text={this.state.searchText}
          style={{ height: 50 }}
          placeholder={'Search'}
          hideBackground={false}
          onChangeText={(text) => this.search.bind(this)(text)} />

        <ListView
          distanceToLoadMore = {0}
          renderScrollComponent={props => <InfiniteScrollView {...props} />}
          dataSource={this.state.dataSource}
          renderRow={this.props.renderCourse}
          canLoadMore={this.state.canLoadMore}
          isLoadingMore={this.state.isLoadingMore}
          onLoadMoreAsync={this.loadMore.bind(this)} />
      </View>
    )
  }
}

export default AllCoursesListView;
