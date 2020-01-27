# Commands:

# https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/

# docker build -t tts -f web.Dockerfile --build-arg env="production" ./
# docker run --rm -it -p 80:80 -e FFMPEG_LOG="true" -e BYPASS_CACHED="true" -e FFMPEG_PATH="/usr/bin/ffmpeg" -e IBM_API_KEY="ndHUMUN-WDu872AfMmVa_vcQDidclpqQRUgi3rk-KZpu" -e GOOGLE_API_KEY="AIzaSyC0vELi8Rl_92yiwCRum7Lhfj88hifzCNw" tts

# docker build -t eu.gcr.io/whisprpoc-212608/tts-cache -f web.Dockerfile --build-arg env="production" ./
# OR
# docker tag tts eu.gcr.io/whisprpoc-212608/tts-cache

# docker push eu.gcr.io/whisprpoc-212608/tts-cache

# You can set the Swift version to what you need for your app. Versions can be found here: https://hub.docker.com/_/swift
FROM swift:4.2 as builder

# For local build, add `--build-arg env=docker`
# In your application, you can use `Environment.custom(name: "docker")` to check if you're in this env

RUN apt-get -qq update && apt-get -q -y install \
  tzdata \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin


# Production image
FROM ubuntu:16.04
ARG env


RUN apt-get -qq update \
  && apt-get -q -y install \
  software-properties-common \
  && add-apt-repository ppa:jonathonf/ffmpeg-4 -y \
  && apt-get -qq update \
  && apt-get install -y \
  libicu55 libxml2 libbsd0 libcurl3 libatomic1 \
  tzdata \
  ffmpeg \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/bin/Run .
COPY --from=builder /build/lib/* /usr/lib/
# Uncomment the next line if you need to load resources from the `Public` directory
#COPY --from=builder /app/Public ./Public
# Uncomment the next line if you are using Leaf
#COPY --from=builder /app/Resources ./Resources
ENV ENVIRONMENT=$env

ENTRYPOINT ./Run serve --env $ENVIRONMENT --hostname 0.0.0.0 --port 80
