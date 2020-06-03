ARG HTTP_PROXY=http://proxyserver:3128/

FROM openjdk:11
ARG HTTP_PROXY

# Configure apt proxy
RUN if [ -n "${HTTP_PROXY}" ]; then \
        echo "Acquire::http::No-Cache True;\
            \nAcquire::https::No-Cache True;\
            \nAcquire::http::Pipeline-Depth 0;\
            \nAcquire::http::Timeout 30;\
            \nAcquire::BrokenProxy True;" > /etc/apt/apt.conf; \
        echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf; \
        echo "Acquire::https::Proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf; \
        cat /etc/apt/apt.conf; \
    fi

# Install base packages, Webkit for GTK-3 / OpenGL libs / + utilities
RUN apt-get update && apt-get install -y \
    curl apt-transport-https debconf-utils \
    mesa-utils libgl1-mesa-glx libgl1-mesa-dri \
    nano \
    sshpass

# Configure broadway
ENV BROADWAY_DISPLAY=:5
ENV BROADWAY_PORT=5000
EXPOSE 5000
ENV GDK_BACKEND=broadway

# Get Eclipse IDE
RUN echo "Downloading Eclipse" && \
    cd /root && \
    curl -x ${HTTP_PROXY} "http://ftp.osuosl.org/pub/eclipse/technology/epp/downloads/release/2020-06/M3/eclipse-java-2020-06-M3-linux-gtk-x86_64.tar.gz" | tar xz && \
    cd eclipse/ && \
    echo $'name=Eclipse IDE\n\
id=org.eclipse.ui.ide.workbench\n\
version=4.16.0' > .eclipseproduct

# Prepare project area
RUN mkdir /projects
VOLUME /projects

RUN for f in "/etc" "/var/run" "/projects" "/root"; do \
    	chgrp -R 0 ${f} && \
    	chmod -R g+rwX ${f}; \
    done

COPY .fonts.conf /root/
COPY .fonts.conf /

#Useful for debug
#RUN dnf -y install gdb gdb-gdbserver java-11-openjdk-devel

COPY ./init.sh /
ENTRYPOINT [ "/init.sh" ]
