FROM apache/drill:1.21.1 as ow-drill
VOLUME /data

USER root
RUN apt-get update && apt-get install -y less mc ncdu git tmux vim
USER $DRILL_USER
COPY ./*.conf $DRILL_HOME/conf/

ENV DRILLBIT_MAX_PROC_MEM=100% \
    DRILL_HEAP=40G \
    DRILL_MAX_DIRECT_MEMORY=40G \
    DRILLBIT_CODE_CACHE_SIZE=1024M 

ENTRYPOINT [ "/opt/drill/bin/drill-embedded" ]

FROM ow-drill as ow-drill-1
COPY run.sql ./
ENTRYPOINT [ "/opt/drill/bin/drill-embedded", "-f", "run.sql" ]
