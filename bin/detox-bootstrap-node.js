#!/usr/bin/env node
(function(){
  /**
   * @package Detox bootstrap node
   * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
   * @license 0BSD
   */
  var detoxBootstrapNode, detoxCrypto, yargs, ID_LENGTH, SEED_LENGTH, argv, instance;
  detoxBootstrapNode = require('..');
  detoxCrypto = require('@detox/crypto');
  yargs = require('yargs');
  ID_LENGTH = 32;
  SEED_LENGTH = ID_LENGTH;
  argv = yargs.command('$0 <seed> <ip> [domain_name]', '', function(){
    yargs.positional('seed', {
      coerce: function(seed){
        seed = Buffer.from(seed, 'hex');
        if (seed.length !== SEED_LENGTH) {
          throw new Error('Incorrect seed length');
        }
        return seed;
      },
      description: 'Hex string of 32-byte seed used for DHT keypair',
      type: 'string'
    }).positional('ip', {
      coerce: function(ip){
        var ip_split, i$, len$, part;
        ip_split = ip.split('.').map(function(num){
          return parseInt(num);
        });
        if (ip_split.length !== 4) {
          throw new Error('Incorrect IP');
        }
        for (i$ = 0, len$ = ip_split.length; i$ < len$; ++i$) {
          part = ip_split[i$];
          if (part > 255) {
            throw new Error('Incorrect IP');
          }
        }
        return ip_split.join('.');
      },
      description: 'IP on which to listen',
      type: 'string'
    }).positional('domain_name', {
      description: 'Publicly available address',
      type: 'string'
    });
  }).option('port', {
    alias: 'p',
    'default': 16882,
    description: 'Port on which to listen',
    type: 'number'
  }).option('bootstrap-node', {
    alias: 'b',
    coerce: function(bootstrap_nodes){
      var i$, len$, bootstrap_node, ref$, node_id, host, port, results$ = [];
      if (!Array.isArray(bootstrap_nodes)) {
        bootstrap_nodes = [bootstrap_nodes];
      }
      for (i$ = 0, len$ = bootstrap_nodes.length; i$ < len$; ++i$) {
        bootstrap_node = bootstrap_nodes[i$];
        ref$ = bootstrap_node.split(':'), node_id = ref$[0], host = ref$[1], port = ref$[2];
        node_id = Buffer.from(node_id, 'hex');
        port = parseInt(port);
        if (node_id.length !== ID_LENGTH) {
          throw new Error("Incorrect node_id length in " + bootstrap_node);
        }
        results$.push({
          node_id: node_id,
          host: host,
          port: port
        });
      }
      return results$;
    },
    description: 'Bootstrap nodes to connect to on start, add at least a few of them (to join existing network) as node_id:host:port',
    type: 'string'
  }).help().argv;
  instance = detoxBootstrapNode.Bootstrap_node(argv.seed, argv.bootstrapNode || [], argv.ip, argv.port, argv.domain_name || argv.ip, [], 10, 100, {
    maxTables: Math.pow(10, 6),
    maxPeers: Math.pow(10, 6)
  }).on('ready', function(){
    var dht_keypair, node_id, host, port;
    dht_keypair = detoxCrypto.create_keypair(argv.seed);
    node_id = Buffer.from(dht_keypair.ed25519['public']).toString('hex');
    host = argv.domain_name || argv.ip;
    port = argv.port;
    console.log('Bootstrap node is ready, connect using:');
    console.log(JSON.stringify({
      node_id: node_id,
      host: host,
      port: port
    }, null, '  '));
  });
  process.on('SIGINT', function(){
    console.log('Got a SIGINT, stop everything and exit');
    instance.stop();
    process.exit(0);
  });
}).call(this);
