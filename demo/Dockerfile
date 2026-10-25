FROM ruby:3.4-alpine

WORKDIR /app

# The version run.sh checks; ">= 0", the latest, when it is empty
ARG LOGDASH_VERSION
RUN gem install logdash --version "${LOGDASH_VERSION:->= 0}"

COPY demo/demo_script.rb /app/

RUN chmod +x /app/demo_script.rb

CMD ["./demo_script.rb"]
