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
!function Bootstrap_node (
	bootstrap_keypair_seed
	bootstrap_nodes
	ip
	port
	public_address = ip
	public_port = port
	ice_servers = []
	# TODO: Below are almost random numbers, need to be tested under load and likely tweaked, but should work for now
	packets_per_second = 10
	bucket_size = 50
	max_pending_segments = 10
	options = {
		state_history_size		: 10 ^ 5
		values_cache_size		: 10 ^ 4
		connected_nodes_limit	: 10 ^ 3
	}
)
	if !(@ instanceof Bootstrap_node)
		return new Bootstrap_node(bootstrap_keypair_seed, bootstrap_nodes, ip, port, public_address, public_port, ice_servers, packets_per_second, bucket_size, max_pending_segments, options)
	async-eventer.call(@)

	<~! detox-core.ready
	@_core_instance	= detox-core.Core(bootstrap_nodes, ice_servers, packets_per_second, bucket_size, max_pending_segments, options)
		.on('ready', !~>
			@fire('ready')
		)
		.on('connected_nodes_count', (count) !~>
			@fire('connected_nodes_count', count)
		)
	@_core_instance.start_bootstrap_node(bootstrap_keypair_seed, ip, port, public_address, public_port)

# TODO: Node introspection methods, possibly for dynamic CLI UI or debugging purposes
Bootstrap_node:: =
	stop : !->
		@_core_instance.destroy()

Bootstrap_node:: = Object.assign(Object.create(async-eventer::), Bootstrap_node::)
