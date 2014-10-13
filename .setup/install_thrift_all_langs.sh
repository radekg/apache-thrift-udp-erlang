# No D support. Trying install with D, the following error occurs:
#    root@precise64:/vagrant/.vagrant_install/thrift/lib/d# make
#    Making all in .
#    make[1]: Entering directory `/vagrant/.vagrant_install/thrift/lib/d'
#    gdmd -oflibthriftd.a -w -wi -Isrc -lib src/thrift/base.d src/thrift/async/base.d src/thrift/async/socket.d src/thrift/codegen/async_client.d src/thrift/codegen/async_client_pool.d src/thrift/codegen/base.d src/thrift/codegen/client.d src/thrift/codegen/client_pool.d src/thrift/codegen/idlgen.d src/thrift/codegen/processor.d src/thrift/protocol/base.d src/thrift/protocol/binary.d src/thrift/protocol/compact.d src/thrift/protocol/json.d src/thrift/protocol/processor.d src/thrift/server/base.d src/thrift/server/simple.d src/thrift/server/taskpool.d src/thrift/server/threaded.d src/thrift/server/transport/base.d src/thrift/server/transport/socket.d src/thrift/transport/base.d src/thrift/transport/buffered.d src/thrift/transport/file.d src/thrift/transport/framed.d src/thrift/transport/http.d src/thrift/transport/memory.d src/thrift/transport/piped.d src/thrift/transport/range.d src/thrift/transport/socket.d src/thrift/transport/zlib.d src/thrift/util/awaitable.d src/thrift/util/cancellation.d src/thrift/util/future.d src/thrift/util/hashset.d src/thrift/internal/algorithm.d src/thrift/internal/codegen.d src/thrift/internal/ctfe.d src/thrift/internal/endian.d src/thrift/internal/resource_pool.d src/thrift/internal/socket.d src/thrift/internal/traits.d src/thrift/internal/test/protocol.d src/thrift/internal/test/server.d
#    src/thrift/async/socket.d:106: Error: undefined identifier getAddress
#    src/thrift/async/socket.d:116: Error: class std.socket.Address member name is not accessible
#    src/thrift/async/socket.d:116: Error: class std.socket.Address member nameLen is not accessible
#    src/thrift/async/socket.d:134: Error: function thrift.async.base.TAsyncManager.execute (TAsyncTransport transport, void delegate() work, TCancellation cancellation = cast(TCancellation)null) is not callable using argument types (TAsyncSocket,_error_ delegate())
#    src/thrift/async/socket.d:135: Error: cannot implicitly convert expression (__dgliteral1) of type _error_ delegate() to void delegate()

apt-get update -y

if [ -z "$(thrift -version)" ]; then
  
  apt-get install python-software-properties -y
  add-apt-repository ppa:duh/golang -y
  apt-get update -y
  
  apt-get install -y git-core build-essential \
    libboost-dev libboost-test-dev libboost-program-options-dev \
    libevent-dev automake libtool flex bison pkg-config g++ libssl-dev \
    mono-gmcs libmono-2.0-1 mono-devel \
    libglib2.0-dev \
    openjdk-6-jdk maven2 \
    python-dev python-twisted \
    ruby-dev librspec-ruby rake rubygems \
    ghc6 cabal-install libghc6-binary-dev libghc6-network-dev libghc6-http-dev \
    libbit-vector-perl \
    php5 php5-dev \
    erlang \
    golang
    #gdc \

  # For Ruby, install dependencies
  gem install bundler --version "=1.3.1"

  # for Haskell, install dependencies
  cabal update
  cabal install hashable --global
  cabal install unordered-containers --global
  cabal install vector --global

  WORKING_DIR=$(pwd)/thrift-src

  mkdir -p $WORKING_DIR && cd $WORKING_DIR

  if [ ! -d $WORKING_DIR/.git ]; then
    git clone https://github.com/apache/thrift.git .
    git fetch origin
    git checkout -b 0.9.1 origin/0.9.1
  fi

  ./bootstrap.sh
  ./configure --with-boost=/usr/local
  make
  make install
  cd /
  rm -Rf $WORKING_DIR
  
fi