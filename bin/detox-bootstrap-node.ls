``#!/usr/bin/env node``
/**
 * @package Detox bootstrap node
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
detox-bootstrap-node	= require('..')
detox-crypto			= require('@detox/crypto')
detox-core				= require('@detox/core')
yargs					= require('yargs')

const ID_LENGTH		= 32
const SEED_LENGTH	= ID_LENGTH

console.log 'Detox bootstrap node'

bootstrap_node_option	=
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
			node_id					= node_id.toString('hex')
			{node_id, host, port}
	description	: 'Bootstrap nodes, add at least a few to join existing network as node_id:host:port'
	type		: 'string'
yargs
	.command(
		'$0 <seed> <ip> [domain_name]'
		'Start bootstrap node'
		!->
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
				.option('port', {
					alias		: 'p'
					default		: 16882
					description	: 'Port on which to listen'
					type		: 'number'
				})
				.option('bootstrap-node', bootstrap_node_option)
		start_bootstrap_node
	)
	.command(
		'dummy-clients <number_of_clients>'
		'Run dummy clients'
		!->
			yargs
				.positional('number_of_clients', {
					coerce		: (number_of_clients) ->
						number_of_clients	= parseInt(number_of_clients)
						if number_of_clients < 1
							throw new Error('Incorrect number of clients, should be 1 or more')
						number_of_clients
					description	: 'How many clients to run (can run many in the same process'
					type		: 'number'
				})
				.option('bootstrap-node', Object.assign({required: true}, bootstrap_node_option))
		start_dummy_clients
	)
	.help()
	.argv

!function start_bootstrap_node (argv)
	console.log 'Starting bootstrap node...'
	instance = detox-bootstrap-node.Bootstrap_node(
		argv.seed
		argv.bootstrap-node || []
		argv.ip
		argv.port
		argv.domain_name || argv.ip
		[]
		# TODO: Below are almost random numbers, need to be tested under load and likely tweaked, but should work for now
		10
		50
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
			console.log 'Bootstrap node is ready!'
			console.log 'Connect in web UI:'
			console.log JSON.stringify({node_id, host, port}, null, '  ')
			console.log 'Or for CLI:'
			console.log JSON.stringify("#node_id:#host:#port")
		)

	process.on('SIGINT', !->
		console.log 'Got a SIGINT, stop everything and exit'
		instance.stop()
		process.exit(0)
	)

!function start_dummy_clients (argv)
	console.log 'Starting dummy clients...'
	<~! detox-core.ready
	number_of_clients	= argv.number_of_clients
	wait_for			= number_of_clients
	instances			= []

	for let i from 0 til number_of_clients
		instance	= detox-core.Core(
			detox-core.generate_seed()
			argv.bootstrap-node
			[]
			10
			10
		)
			.once('ready', !->
				console.log('Node ' + i + ' is ready, #' + (number_of_clients - wait_for + 1) + '/' + number_of_clients)

				--wait_for
				if !wait_for
					ready_callback()
			)
		instances.push(instance)

	!function ready_callback
		console.log 'All dummy nodes are ready'

	process.on('SIGINT', !->
		console.log 'Got a SIGINT, stop everything and exit'
		for instance in instances
			instance.destroy()
		process.exit(0)
	)
