rosbuild_find_ros_package(genmsg_cpp)
rosbuild_find_ros_package(roseus)

# for euslisp ros API. like roslib.load_mafest
macro(genmanifest_eus)
  rosbuild_find_ros_package(roseus)
  set(genmanifest_eus_exe ${roseus_PACKAGE_PATH}/scripts/genmanifest_eus)
  set(manifest_eus_target_dir ${PROJECT_SOURCE_DIR}/src/euslisp)
  set(manifest_eus_target ${manifest_eus_target_dir}/_manifest.l)
  set(manifest_xml ${PROJECT_SOURCE_DIR}/manifest.xml)
  rosbuild_invoke_rospack(${PROJECT_NAME} _rospack deps_packages depends)
  if(NOT "" STREQUAL ${_rospack_deps_packages})
    string(REPLACE "\n" " " _rospack_deps_packages ${_rospack_deps_packages})
    add_custom_command(OUTPUT ${manifest_eus_target}
      ${manifest_eus_target_dir}
      COMMAND "mkdir" "-p"  ${manifest_eus_target_dir}
      COMMAND ${genmanifest_eus_exe} ${manifest_eus_target}
      ${_rospack_deps_packages}
      DEPENDS ${manifest_xml})
    add_custom_target(ROSBUILD_genmanifest_eus ALL
      DEPENDS ${manifest_eus_target} ${genmanifest_eus_exe})
  endif(${_rospack_deps_packages})
endmacro(genmanifest_eus)
genmanifest_eus()

# Message-generation support.
macro(genmsg_eus)
  rosbuild_get_msgs(_msglist)
  set(_autogen "")
  foreach(_msg ${_msglist})
    # Construct the path to the .msg file
    set(_input ${PROJECT_SOURCE_DIR}/msg/${_msg})

    rosbuild_gendeps(${PROJECT_NAME} ${_msg})
    rosbuild_find_ros_package(roseus)
    set(genmsg_eus_exe ${roseus_PACKAGE_PATH}/scripts/genmsg_eus)

    set(_output_eus ${PROJECT_SOURCE_DIR}/msg/eus/${PROJECT_NAME}/${_msg})
    string(REPLACE ".msg" ".l" _output_eus ${_output_eus})

    # Add the rule to build the .h the .msg
    add_custom_command(OUTPUT ${_output_eus}
                       COMMAND ${genmsg_eus_exe} ${_input}
                       DEPENDS ${_input} ${genmsg_eus_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_msg}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_eus})
  endforeach(_msg)
  # Create a target that depends on the union of all the autogenerated
  # files
  add_custom_target(ROSBUILD_genmsg_eus DEPENDS ${_autogen})
  # Add our target to the top-level genmsg target, which will be fired if
  # the user calls genmsg()
  add_dependencies(rospack_genmsg ROSBUILD_genmsg_eus)
endmacro(genmsg_eus)

# Call the macro we just defined.
genmsg_eus()

# Service-generation support.
macro(gensrv_eus)
  rosbuild_get_srvs(_srvlist)
  set(_autogen "")
  foreach(_srv ${_srvlist})
    # Construct the path to the .srv file
    set(_input ${PROJECT_SOURCE_DIR}/srv/${_srv})

    rosbuild_gendeps(${PROJECT_NAME} ${_srv})
    rosbuild_find_ros_package(roseus)
    set(gensrv_eus_exe ${roseus_PACKAGE_PATH}/scripts/gensrv_eus)

    set(_output_eus ${PROJECT_SOURCE_DIR}/srv/eus/${PROJECT_NAME}/${_srv})
    string(REPLACE ".srv" ".l" _output_eus ${_output_eus})

    # Add the rule to build the .h from the .srv
    add_custom_command(OUTPUT ${_output_eus}
                       COMMAND ${gensrv_eus_exe} ${_input}
                       DEPENDS ${_input} ${gensrv_eus_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_srv}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_eus})
  endforeach(_srv)
  # Create a target that depends on the union of all the autogenerated
  # files
  add_custom_target(ROSBUILD_gensrv_eus DEPENDS ${_autogen})
  # Add our target to the top-level gensrv target, which will be fired if
  # the user calls gensrv()
  add_dependencies(rospack_gensrv ROSBUILD_gensrv_eus)
endmacro(gensrv_eus)

# Call the macro we just defined.
gensrv_eus()

