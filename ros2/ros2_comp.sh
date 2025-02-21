if [ -n "${ROS2_CONFIGURATION_COMPLETED+x}" ]; then
    eval "$(register-python-argcomplete3 ros2)"
    eval "$(register-python-argcomplete3 colcon)"
    unset ROS2_CONFIGURATION_COMPLETED
fi