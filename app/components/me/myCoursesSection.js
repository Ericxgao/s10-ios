import React, {
  Text,
  TouchableOpacity,
  View,
  StyleSheet,
  Image
} from 'react-native';

import { TappableCard } from '../lib/Card';
import Loader from '../lib/Loader';
import { SHEET, COLORS } from '../../CommonStyles'
import Routes from '../../nav/Routes'
import { formatCourse } from '../courses/coursesCommon'
import { AddNewClassCard } from '../courses/MyCoursesScreen'
const logger = new (require('../../../modules/Logger'))('renderCourse');

function renderCourses(courses, navigator) {

  if (!courses.loaded) {
    return (<Loader />)
  }

  if (courses.loadedCourses.length == 0) {
    return (
      <AddNewClassCard navigator={navigator} />
    )
  }

  return (
    <TappableCard onPress={(event) => {
        const route = Routes.instance.getMyCoursesListRoute(courses);
        navigator.push(route);
      }}>
      <View style={styles.courseContainer}>
        {courses.loadedCourses.map(course => { return renderCourseTag(course) })}
      </View>
    </TappableCard>
  )
}

function renderCourseTag(course) {
  return (
    <View style={styles.courseTag} key={course._id}>
      <Image
        style={styles.courseTagIcon}
        source={require('../img/ic-class-icon.png')}
        />
      <Text style={[SHEET.baseText, styles.courseTagText]}>{formatCourse(course.dept, course.course)}</Text>
    </View>
  )
}

var styles = StyleSheet.create({
  courseContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -8,
    marginVertical: -5,
    alignItems: 'flex-start',
  },
  courseTag: {
    backgroundColor: COLORS.taylr,
    padding: 7,
    flexDirection: 'row',
    margin: 8,
  },
  courseTagIcon: {
    width: 26,
    height: 20,
  },
  courseTagText: {
    fontSize: 14,
    color: 'white',
    marginLeft: 6,
  },
});


export default renderCourses
