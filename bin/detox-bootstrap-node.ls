``#!/usr/bin/env node``
/**
 * @package Detox bootstrap node
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
detox-bootstrap-node	= require('..')
detox-crypto			= require('@detox/crypto')
yargs					= require('yargs')

const ID_LENGTH		= 32
const SEED_LENGTH	= ID_LENGTH

argv	= yargs
	.command('$0 <seed> <ip> [domain_name]', '', !->
		yargs
			.positional('seed', {
				coerce		: (seed) ->
					seed	= Buffer.from(seed, 'hex')
					if seed.length != SEED_LENGTH
						throw new Error('Incorrect seed length')
					seed
				description	: 'Hex string of 32-byte seed used for DHT keypair'
				type		: 'string'
			})
			.positional('ip', {
				coerce		: (ip) ->
					ip_split	= ip.split('.').map (num) ->
						parseInt(num)
					if ip_split.length != 4
						throw new Error('Incorrect IP')
					for part in ip_split
						if part > 255
							throw new Error('Incorrect IP')
					ip_split.join('.')
				description	: 'IP on which to listen'
				type		: 'string'
			})
			.positional('domain_name', {
				description	: 'Publicly available address'
				type		: 'string'
			})
	)
	.option('port', {
		alias		: 'p'
		default		: 16882
		description	: 'Port on which to listen'
		type		: 'number'
	})
	.option('bootstrap-node', {
		alias		: 'b'
		coerce		: (bootstrap_nodes) ->
			if !Array.isArray(bootstrap_nodes)
				bootstrap_nodes	= [bootstrap_nodes]
			for bootstrap_node in bootstrap_nodes
				[node_id, host, port]	= bootstrap_node.split(':')
				node_id					= Buffer.from(node_id, 'hex')
				port					= parseInt(port)
				if node_id.length != ID_LENGTH
					throw new Error("Incorrect node_id length in #bootstrap_node")
				{node_id, host, port}
		description	: 'Bootstrap nodes to connect to on start, add at least a few of them (to join existing network) as node_id:host:port'
		type		: 'string'
	})
	.help()
	.argv

instance = detox-bootstrap-node.Bootstrap_node(
	argv.seed
	argv.bootstrap-node || []
	argv.ip
	argv.port
	argv.domain_name || argv.ip
	[]
	# TODO: Below are almost random numbers, need to be tested under load and likely tweaked, but should work for now
	10
	100
	{
		maxTables	: 10 ^ 6
		maxPeers	: 10 ^ 6
	}
)
	.on('ready', !->
		dht_keypair	= detox-crypto.create_keypair(argv.seed)
		node_id		= Buffer.from(dht_keypair.ed25519.public).toString('hex')
		host		= argv.domain_name || argv.ip
		port		= argv.port
		console.log 'Bootstrap node is ready, connect using:'
		console.log JSON.stringify({node_id, host, port}, null, '  ')
	)

process.on('SIGINT', !->
	console.log 'Got a SIGINT, stop everything and exit'
	instance.stop()
	process.exit(0)
)
