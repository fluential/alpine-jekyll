FROM alpine:3.12

ENV OUTPUT_DIR '/var/_site'
ENV INPUT_DIR '/var/_source'
ENV INPUT_EXTRA_PARAMETERS ''

# Copy entrypoint script
COPY ./entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

# Install jekyll app
COPY ./app/* /app/

WORKDIR /app
# install dev deps in --virtual, gem install and cleanup
RUN apk add --update ruby cargo rustup curl npm cmake clang python3 git make g++ openssl-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly --no-modify-path \
    && apk add --virtual build-dependencies build-base ruby-dev libffi-dev && npm install terser -g\
    && gem install bundler --no-document \
    && bundle install --without development test \
    && gem cleanup \
    && source $HOME/.cargo/env && rustup install nightly && rustup override set nightly && rustup target add asmjs-unknown-emscripten --toolchain nightly && rustup target add wasm32-unknown-emscripten --toolchain nightly

RUN git clone https://github.com/WebAssembly/binaryen && \
      cd binaryen && \
      cmake -j $(nproc) . && make install
RUN cargo install tinysearch && apk del build-dependencies cmake clang g++ openssl-dev
RUN rm -rf binaryen

CMD ["/bin/sh"]
