##Welcome to the kr1warren/mkimage-yum.sh wiki!

Original source code for mkimage-yum.sh is located at: https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh

#Primary enhancements with this version include the following:

    Corrected ability to install multiple packages by adding a for loop.
    Added ability to remove multiple packages.
    Differentiate between environment groups and regular groups.
    Added the /etc/docker-image-info file to record actions taking creating the container.
    Added ability to use local repository. Which by default is enabled. Should disable this if public repositories to be used.
    Added a creator option to record name of person who created the image to the layer history and info file.

