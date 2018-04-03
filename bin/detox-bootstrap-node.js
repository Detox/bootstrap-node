#!/usr/bin/env node
(function(){
  /**
   * @package Detox bootstrap node
   * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
   * @license 0BSD
   */
  var detoxBootstrapNode, detoxCrypto, detoxCore, yargs, ID_LENGTH, SEED_LENGTH, bootstrap_node_option;
  detoxBootstrapNode = require('..');
  detoxCrypto = require('@detox/crypto');
  detoxCore = require('@detox/core');
  yargs = require('yargs');
  ID_LENGTH = 32;
  SEED_LENGTH = ID_LENGTH;
  console.log('Detox bootstrap node');
  bootstrap_node_option = {
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
        node_id = node_id.toString('hex');
        results$.push({
          node_id: node_id,
          host: host,
          port: port
        });
      }
      return results$;
    },
    description: 'Bootstrap nodes, add at least a few to join existing network as node_id:host:port',
    type: 'string'
  };
  yargs.command('$0 <seed> <ip> [domain_name]', 'Start bootstrap node', function(){
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
    }).option('port', {
      alias: 'p',
      'default': 16882,
      description: 'Port on which to listen',
      type: 'number'
    }).option('bootstrap-node', bootstrap_node_option);
  }, start_bootstrap_node).command('dummy-clients <number_of_clients>', 'Run dummy clients', function(){
    yargs.positional('number_of_clients', {
      coerce: function(number_of_clients){
        number_of_clients = parseInt(number_of_clients);
        if (number_of_clients < 1) {
          throw new Error('Incorrect number of clients, should be 1 or more');
        }
        return number_of_clients;
      },
      description: 'How many clients to run (can run many in the same process',
      type: 'number'
    }).option('bootstrap-node', Object.assign({
      required: true
    }, bootstrap_node_option));
  }, start_dummy_clients).command('seed', 'Generates random seed, suitable for starting bootstrap node', generate_seed).option('interactive', {
    alias: 'i',
    description: 'Will display some useful live information about instance',
    type: 'boolean'
  }).option('stun', {
    alias: 's',
    coerce: function(stun_servers){
      var i$, len$, stun_server, results$ = [];
      if (!Array.isArray(stun_servers)) {
        stun_servers = [stun_servers];
      }
      for (i$ = 0, len$ = stun_servers.length; i$ < len$; ++i$) {
        stun_server = stun_servers[i$];
        if (!stun_server.startsWith('stun:')) {
          throw new Error('Incorrect stun server ' + stun_server);
        }
        results$.push({
          urls: stun_server
        });
      }
      return results$;
    },
    description: 'Stun server like stun:stun.l.google.com:19302, add at least one if public IP is not directly assigned to this machine',
    type: 'string'
  }).help().argv;
  function start_bootstrap_node(argv){
    var instance;
    console.log('Starting bootstrap node...');
    instance = detoxBootstrapNode.Bootstrap_node(argv.seed, argv.bootstrapNode || [], argv.ip, argv.port, argv.domain_name || argv.ip, argv.stun || []).on('ready', function(){
      var dht_keypair, node_id, host, port, last_length, update;
      dht_keypair = detoxCrypto.create_keypair(argv.seed);
      node_id = Buffer.from(dht_keypair.ed25519['public']).toString('hex');
      host = argv.domain_name || argv.ip;
      port = argv.port;
      console.log('Bootstrap node is ready!');
      console.log('Connect in web UI:');
      console.log(JSON.stringify({
        node_id: node_id,
        host: host,
        port: port
      }, null, '  '));
      console.log('Or for CLI:');
      console.log(JSON.stringify(node_id + ":" + host + ":" + port));
      if (argv.interactive) {
        console.log("\nBootstrap node stats:");
        last_length = 0;
        update = function(count){
          var to_print;
          process.stdout.write("\r" + ' '.repeat(last_length));
          to_print = "Connected nodes : " + count;
          process.stdout.write("\r" + to_print);
          last_length = to_print.length;
        };
        update(0);
        instance.on('connected_nodes_count', update);
      }
    });
    process.on('SIGINT', function(){
      console.log("\nGot a SIGINT, stop everything and exit");
      instance.stop();
      process.exit(0);
    });
  }
  function start_dummy_clients(argv){
    var this$ = this;
    console.log('Starting dummy clients...');
    detoxCore.ready(function(){
      var number_of_clients, wait_for, instances, i$, to$;
      number_of_clients = argv.number_of_clients;
      wait_for = argv.number_of_clients;
      instances = [];
      for (i$ = 0, to$ = argv.number_of_clients; i$ < to$; ++i$) {
        (fn$.call(this$, i$));
      }
      function ready_callback(){
        console.log('All dummy clients are ready');
      }
      process.on('SIGINT', function(){
        var i$, ref$, len$, instance;
        console.log("\nGot a SIGINT, stop everything and exit");
        for (i$ = 0, len$ = (ref$ = instances).length; i$ < len$; ++i$) {
          instance = ref$[i$];
          instance.destroy();
        }
        process.exit(0);
      });
      function fn$(i){
        var instance;
        instance = detoxCore.Core(detoxCore.generate_seed(), argv.bootstrapNode, argv.stun || [], 10, 10).once('ready', function(){
          console.log('Node ' + i + ' is ready, #' + (argv.number_of_clients - wait_for + 1) + '/' + argv.number_of_clients);
          --wait_for;
          if (!wait_for) {
            ready_callback();
          }
        });
        instances.push(instance);
      }
    });
  }
  function generate_seed(){
    var this$ = this;
    detoxCrypto.ready(function(){
      var seed, keypair;
      seed = detoxCore.generate_seed();
      keypair = detoxCrypto.create_keypair(seed);
      console.log('Seed: ' + Buffer.from(seed).toString('hex'));
      console.log('Node ID: ' + Buffer.from(keypair.ed25519['public']).toString('hex'));
    });
  }
}).call(this);
