FROM alpine
RUN apk add fortune
COPY fortune_writer.sh /fortune_writer.sh
VOLUME /var/local/output
ENTRYPOINT ["/fortune_writer.sh"]
