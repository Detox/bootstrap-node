#!/usr/bin/env node
(function(){
  /**
   * @package Detox bootstrap node
   * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
   * @license 0BSD
   */
  var detoxBootstrapNode, detoxCrypto, yargs, SEED_LENGTH, argv;
  detoxBootstrapNode = require('..');
  detoxCrypto = require('@detox/crypto');
  yargs = require('yargs');
  SEED_LENGTH = 32;
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
    describe: 'Port on which to listen'
  }).help().argv;
  detoxBootstrapNode.Bootstrap_node(argv.seed, [], argv.ip, argv.port, argv.domain_name || argv.ip, [], 5, 100).on('ready', function(){
    var dht_keypair, node_id, host, port;
    dht_keypair = detoxCrypto.create_keypair(argv.seed);
    node_id = Buffer.from(dht_keypair.ed25519['public']).toString('hex');
    host = argv.domain_name || argv.ip;
    port = argv.port;
    console.log("Bootstrap node is ready, connect using:");
    console.log(JSON.stringify({
      node_id: node_id,
      host: host,
      port: port
    }, null, '  '));
  });
}).call(this);
