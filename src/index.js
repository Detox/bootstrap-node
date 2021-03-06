// Generated by LiveScript 1.5.0
/**
 * @package Detox bootstrap node
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var asyncEventer, detoxCore;
  asyncEventer = require('async-eventer');
  detoxCore = require('@detox/core');
  module.exports = {
    Bootstrap_node: Bootstrap_node
  };
  /**
   * @constructor
   *
   * @param {!Uint8Array}		bootstrap_keypair_seed	Seed used for bootstrap node's keypair
   * @param {!Array<!Object>}	bootstrap_nodes
   * @param {string}			ip
   * @param {number}			port
   * @param {string}			public_address			Publicly available address that will be returned to other node, typically domain name (instead of using IP)
   * @param {number}			public_port				Publicly available port on `address`
   * @param {!Array<!Object>}	ice_servers
   * @param {number}			packets_per_second		Each packet send in each direction has exactly the same size and packets are sent at fixed rate (>= 1)
   * @param {number}			bucket_size
   * @param {number}			max_pending_segments	How much routing segments can be in pending state per one address
   * @param {!Object}			options					Other options, see `@detox/core` for details
   *
   * @return {!Bootstrap_node}
   *
   * @throws {Error}
   */
  function Bootstrap_node(bootstrap_keypair_seed, bootstrap_nodes, ip, port, public_address, public_port, ice_servers, packets_per_second, bucket_size, max_pending_segments, options){
    var this$ = this;
    public_address == null && (public_address = ip);
    public_port == null && (public_port = port);
    ice_servers == null && (ice_servers = []);
    packets_per_second == null && (packets_per_second = 10);
    bucket_size == null && (bucket_size = 50);
    max_pending_segments == null && (max_pending_segments = 10);
    options == null && (options = {
      state_history_size: Math.pow(10, 5),
      values_cache_size: Math.pow(10, 4),
      connected_nodes_limit: Math.pow(10, 3)
    });
    if (!(this instanceof Bootstrap_node)) {
      return new Bootstrap_node(bootstrap_keypair_seed, bootstrap_nodes, ip, port, public_address, public_port, ice_servers, packets_per_second, bucket_size, max_pending_segments, options);
    }
    asyncEventer.call(this);
    detoxCore.ready(function(){
      this$._core_instance = detoxCore.Core(bootstrap_nodes, ice_servers, packets_per_second, bucket_size, max_pending_segments, options).on('ready', function(){
        this$.fire('ready');
      }).on('connected_nodes_count', function(count){
        this$.fire('connected_nodes_count', count);
      });
      this$._core_instance.start_bootstrap_node(bootstrap_keypair_seed, ip, port, public_address, public_port);
    });
  }
  Bootstrap_node.prototype = {
    stop: function(){
      this._core_instance.destroy();
    }
  };
  Bootstrap_node.prototype = Object.assign(Object.create(asyncEventer.prototype), Bootstrap_node.prototype);
}).call(this);
