FROM apache/drill:latest
VOLUME /data

USER root
RUN apt-get update && apt-get install -y less mc ncdu git tmux vim
USER $DRILL_USER
COPY ./*.conf $DRILL_HOME/conf/
COPY run.sql ./
# RUN echo  >> $DRILL_HOME/conf/drill-env.sh
ENTRYPOINT [ "/opt/drill/bin/drill-embedded", "-f", "run.sql" ]

