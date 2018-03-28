/**
 * @package Detox bootstrap node
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
async-eventer	= require('async-eventer')
detox-core		= require('@detox/core')

module.exports	= {Bootstrap_node}

/**
 * @constructor
 *
 * @param {!Uint8Array}		dht_key_seed			Seed used to generate temporary DHT keypair
 * @param {!Array<!Object>}	bootstrap_nodes
 * @param {string}			ip
 * @param {number}			port
 * @param {string}			address					Publicly available address that will be returned to other node, typically domain name (instead of using IP)
 * @param {!Array<!Object>}	ice_servers
 * @param {number}			packets_per_second		Each packet send in each direction has exactly the same size and packets are sent at fixed rate (>= 1)
 * @param {number}			bucket_size
 * @param {number}			max_pending_segments	How much routing segments can be in pending state per one address
 * @param {!Object}			other_dht_options		Other internal options supported by underlying DHT implementation `webtorrent-dht`
 *
 * @return {!Bootstrap_node}
 *
 * @throws {Error}
 */
!function Bootstrap_node (dht_key_seed, bootstrap_nodes, ip, port, address = ip, ice_servers = [], packets_per_second = 1, bucket_size = 2, max_pending_segments = 10, other_dht_options = {})
	if !(@ instanceof Bootstrap_node)
		return new Bootstrap_node(dht_key_seed, bootstrap_nodes, ip, port, address, ice_servers, packets_per_second, bucket_size, max_pending_segments, other_dht_options)
	async-eventer.call(@)

	<~! detox-core.ready
	@_core_instance	= detox-core.Core(new Uint8Array(32), [], [], 5, 10)
		.on('ready', !~>
			@_core_instance.start_bootstrap_node(ip, port, address)
			@fire('ready')
		)

# TODO: Node introspection methods, possibly for dynamic CLI UI or debugging purposes
Bootstrap_node:: =
	stop : !->
		@_core_instance.destroy()

Bootstrap_node:: = Object.assign(Object.create(async-eventer::), Bootstrap_node::)
