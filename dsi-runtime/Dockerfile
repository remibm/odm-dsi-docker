ARG baseimg

FROM $baseimg

ARG dsi_version

RUN apt-get update --fix-missing
RUN apt-get -y dist-upgrade
RUN apt-get -y install wget

COPY start.sh /root/
COPY dsi-cmd /
COPY jprofiler_config.xml /root/

RUN mkdir -p /opt
ADD /opt /opt

RUN sed -i "s/\/bin\/sh/\/bin\/bash/g" "/opt/dsi/runtime/wlp/bin/xscmd.sh"

CMD /root/start.sh
