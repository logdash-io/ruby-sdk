FROM ruby:3.2-alpine

WORKDIR /app

RUN gem install logdash

COPY demo/demo_script.rb /app/

RUN chmod +x /app/demo_script.rb

CMD ["./demo_script.rb"] 