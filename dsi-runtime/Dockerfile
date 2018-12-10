ARG baseimg

FROM $baseimg

ARG dsi_version

RUN apt-get update --fix-missing
RUN apt-get -y dist-upgrade
RUN apt-get -y install wget
RUN apt-get -y install libpostgresql-jdbc-java
RUN mkdir /jdbc_postgresql
RUN wget -P /jdbc_postgresql https://jdbc.postgresql.org/download/postgresql-42.2.4.jar

COPY start.sh /root/
COPY dsi-cmd /
COPY jprofiler_config.xml /root/

RUN mkdir -p /opt
ADD /opt /opt

RUN sed -i "s/\/bin\/sh/\/bin\/bash/g" "/opt/dsi/runtime/wlp/bin/xscmd.sh"

CMD /root/start.sh
