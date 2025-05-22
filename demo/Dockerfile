FROM ruby:3.2-alpine

WORKDIR /app

# Add --no-cache-dir to prevent gem caching
# Add a cache-busting argument to force re-installation when building
ARG CACHEBUST=1
RUN gem install logdash

# Copy demo script
COPY demo/demo_script.rb /app/

# Set execute permissions
RUN chmod +x /app/demo_script.rb

# Run the demo
CMD ["./demo_script.rb"] 