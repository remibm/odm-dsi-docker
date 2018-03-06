ARG baseimg
ARG dsi_version

FROM $baseimg

RUN apt-get update --fix-missing
RUN apt-get -y dist-upgrade
RUN apt-get -y install wget

COPY start.sh /root/
COPY jprofiler_config.xml /root/

RUN mkdir -p /opt
ADD /opt /opt

RUN sed -i "s/\/bin\/sh/\/bin\/bash/g" "/opt/dsi/runtime/wlp/bin/xscmd.sh"
RUN find /opt/dsi/runtime/wlp/templates/servers/ -name "server.xml" -exec sed -i "s/_DSI_VERSION_/$dsi_version/g" {} \; 

CMD /root/start.sh
