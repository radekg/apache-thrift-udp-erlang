cd /vagrant/private
thrift --gen erl udp_thrift.thrift
mkdir -p ../include
# make the generated code available for the program:
mv gen-erl/udp_thrift_types.erl ../src/udp_thrift_types.erl
mv gen-erl/udp_thrift_constants.hrl ../include/udp_thrift_constants.hrl
mv gen-erl/udp_thrift_types.hrl ../include/udp_thrift_types.hrl
rm -Rf gen-erl