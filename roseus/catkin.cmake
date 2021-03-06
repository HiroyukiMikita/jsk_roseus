# http://ros.org/doc/groovy/api/catkin/html/user_guide/supposed.html
cmake_minimum_required(VERSION 2.8.3)
project(roseus)

# Load catkin and all dependencies required for this package
# TODO: remove all from COMPONENTS that are not catkin packages.
find_package(catkin REQUIRED COMPONENTS roslang roscpp rospack actionlib actionlib_msgs visualization_msgs tf geometry_msgs std_msgs std_srvs sensor_msgs visualization_msgs tf2_ros)

add_definitions(-Wall)
#
execute_process(COMMAND rosversion tf2_ros OUTPUT_VARIABLE TF2_ROS_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "tf2_ros version: ${TF2_ROS_VERSION}")
if(${TF2_ROS_VERSION} VERSION_LESS  0.4.0)
  add_definitions(-DTF2_ROS_VERSION_3)
  message(STATUS "compile with -DTF2_ROS_VERSION_3")
endif()

#set( CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS TRUE )
#if(UNIX AND CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
#  set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR} CACHE PATH "roseus install prefix" FORCE )
#endif()


find_program (SVNVERSION_CMD svnversion)
execute_process (COMMAND "${SVNVERSION_CMD}" ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE SVNVERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE)
message (STATUS "Build svn revision: ${SVNVERSION}")

#
# CATKIN_MIGRATION: removed during catkin migration
# rosbuild_add_boost_directories()

#find_package(euslisp)
find_package(catkin COMPONENTS euslisp)
if(NOT euslisp_FOUND)
  message("-- could not found euslisp (catkin) package, use rospack to find euslisp dir")
  execute_process(COMMAND rospack find euslisp OUTPUT_VARIABLE euslisp_PACKAGE_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(euslisp_INCLUDE_DIRS ${euslisp_PACKAGE_PATH}/jskeus/eus/include)
endif()
message("-- Set euslisp_INCLUDE_DIRS to ${euslisp_INCLUDE_DIRS}")
include_directories(/usr/include /usr/X11R6/include ${euslisp_INCLUDE_DIRS})
add_library(roseus roseus.cpp)
add_library(eustf eustf.cpp)
add_library(roseus_c_util roseus_c_util.c)
target_link_libraries(roseus ${rospack_LIBRARIES} ${roscpp_LIBRARIES})
target_link_libraries(eustf  ${roscpp_LIBRARIES} ${tf_LIBRARIES} ${tf2_ros_LIBRARIES})
set_target_properties(roseus PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/euslisp)
set_target_properties(eustf PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/euslisp)
set_target_properties(roseus_c_util PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/euslisp)

# compile flags
add_definitions(-O2 -Wno-write-strings -Wno-comment)
add_definitions(-Di486 -DLinux -D_REENTRANT -DVERSION='\"${8.26}\"' -DTHREADED -DPTHREAD -DX11R6_1)
add_definitions('-DSVNVERSION="\\"r${SVNVERSION}\\""')
if(${CMAKE_SYSTEM_PROCESSOR} MATCHES amd64* OR
   ${CMAKE_SYSTEM_PROCESSOR} MATCHES x86_64* )
 add_definitions(-Dx86_64)
else()
 add_definitions(-Di486)
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES Darwin)
 add_definitions(-Dx86_64)
 set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS} -flat_namespace -undefined suppress")
endif()

include_directories(${Boost_INCLUDE_DIRS})
target_link_libraries(roseus ${Boost_LIBRARIES})

set_target_properties(roseus PROPERTIES PREFIX "" SUFFIX ".so")
set_target_properties(eustf PROPERTIES PREFIX "" SUFFIX ".so")
set_target_properties(roseus_c_util PROPERTIES PREFIX "" SUFFIX ".so")

add_service_files(
  FILES AddTwoInts.srv StringString.srv
)
add_message_files(
  FILES String.msg StringStamped.msg
)

# CATKIN_MIGRATION: removed during catkin migration
#file(MAKE_DIRECTORY ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}/test)
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/test)
add_executable(simple_execute_ref_server test/simple_execute_ref_server.cpp)
target_link_libraries(simple_execute_ref_server ${roscpp_LIBRARIES} ${actionlib_LIBRARIES})
set_target_properties(simple_execute_ref_server PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/test)
# rosbuild_add_rostest(test/test-talker-listener.launch)
# rosbuild_add_rostest(test/test-add-two-ints.launch)
# rosbuild_add_rostest(test/test-simple-client.launch)
# rosbuild_add_rostest(test/test-simple-client-wait.launch)
# rosbuild_add_rostest(test/test-fibonacci.launch)
# rosbuild_add_rostest(test/test-tf.launch)
# rosbuild_add_rostest(test/test-disconnect.launch)
# rosbuild_add_rostest(test/test-multi-queue.launch)

## Generate added messages and services with any dependencies listed here
generate_messages(
  DEPENDENCIES geometry_msgs std_msgs
)

## LIBRARIES: libraries you create in this project that dependent projects also need
## CATKIN_DEPENDS: catkin_packages dependent projects also need
## DEPENDS: system dependencies of this project that dependent projects also need
catkin_package(
    DEPENDS roslang roscpp rospack actionlib actionlib_msgs visualization_msgs tf geometry_msgs std_msgs std_srvs sensor_msgs visualization_msgs actionlib_tutorials coreutils tf2_ros
    CATKIN-DEPENDS # euslisp TODO
    INCLUDE_DIRS # TODO include
    LIBRARIES # TODO
)

install(PROGRAMS bin/roseus  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})
# set symlink from /opt/groovy/bin to /opt/groovy/share/roseus/roseus
install(CODE "
  file(MAKE_DIRECTORY \"\$ENV{DESTDIR}/\${CMAKE_INSTALL_PREFIX}/bin\")
  message(\"-- CreateLink: \$ENV{DESTDIR}/\${CMAKE_INSTALL_PREFIX}/bin/roseus -> ../${CATKIN_PACKAGE_BIN_DESTINATION}/roseus\")
  execute_process(COMMAND \"${CMAKE_COMMAND}\" -E create_symlink ../${CATKIN_PACKAGE_BIN_DESTINATION}/roseus \$ENV{DESTDIR}/\${CMAKE_INSTALL_PREFIX}/bin/roseus)
")

install(TARGETS roseus  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/euslisp)
install(TARGETS eustf   DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/euslisp)
install(TARGETS roseus_c_util  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/euslisp)
install(DIRECTORY euslisp/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/euslisp
  FILES_MATCHING PATTERN "*.l" PATTERN ".svn" EXCLUDE)

# scripts
install(DIRECTORY cmake/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/cmake
  FILES_MATCHING PATTERN "*.cmake" PATTERN ".svn" EXCLUDE)
file(GLOB scripts "${PROJECT_SOURCE_DIR}/scripts/*")
list(REMOVE_ITEM scripts "${PROJECT_SOURCE_DIR}/scripts/.svn")
install(PROGRAMS ${scripts} DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)

# test codes
install(TARGETS simple_execute_ref_server  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/test)
install(DIRECTORY test
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/test
  FILES_MATCHING PATTERN "*.l" PATTERN "*.launch" PATTERN ".svn" EXCLUDE)
install(DIRECTORY scripts
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts
  PATTERN ".svn" EXCLUDE)

