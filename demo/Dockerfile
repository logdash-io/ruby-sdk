FROM ruby:3.2-alpine

WORKDIR /app

# Install the logdash gem from RubyGems
RUN gem install logdash

# Copy demo script
COPY demo/demo_script.rb /app/

# Set execute permissions
RUN chmod +x /app/demo_script.rb

# Run the demo
CMD ["./demo_script.rb"] 