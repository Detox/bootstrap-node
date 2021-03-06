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
		bootstrap_nodes
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
					description	: "Hex string of 32-byte seed used for bootstrap node's keypair"
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
				.option('public-port', {
					alias		: 'P'
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
	.command(
		'seed'
		'Generates random seed, suitable for starting bootstrap node'
		generate_seed
	)
	.option('interactive', {
		alias		: 'i'
		description	: 'Will display some useful live information about instance'
		type		: 'boolean'
	})
	.option('stun', {
		alias		: 's'
		coerce		: (stun_servers) ->
			if !Array.isArray(stun_servers)
				stun_servers	= [stun_servers]
			for stun_server in stun_servers
				if !stun_server.startsWith('stun:')
					throw new Error('Incorrect stun server ' + stun_server)
				{urls: stun_server}
		description	: 'Stun server like stun:stun.l.google.com:19302, add at least one if public IP is not directly assigned to this machine'
		type		: 'string'
	})
	.help()
	.argv

!function start_bootstrap_node (argv)
	console.log 'Starting bootstrap node...'
	host	= argv.domain_name || argv.ip
	port	= argv.public-port || argv.port
	instance = detox-bootstrap-node.Bootstrap_node(
		argv.seed
		argv.bootstrap-node || []
		argv.ip
		argv.port
		host
		port
		argv.stun || []
	)
		.on('ready', !->
			bootstrap_node_keypair	= detox-crypto.create_keypair(argv.seed)
			node_id					= Buffer.from(bootstrap_node_keypair.ed25519.public).toString('hex')
			console.log 'Bootstrap node is ready!'
			console.log 'Connect via:'
			console.log "#node_id:#host:#port"

			if argv.interactive
				console.log "\nBootstrap node stats:"
				last_length	= 0
				update	= (count) !->
					process.stdout.write("\r" + ' '.repeat(last_length))
					to_print	= "Connected nodes : #count"
					process.stdout.write("\r#to_print")
					last_length	:= to_print.length
				update(0)
				instance.on('connected_nodes_count', update)
		)

	process.on('SIGINT', !->
		console.log "\nGot a SIGINT, stop everything and exit"
		instance.stop()
		process.exit(0)
	)
	process.on('SIGTERM', !->
		console.log "\nGot a SIGTERM, stop everything and exit"
		instance.stop()
		process.exit(0)
	)

!function start_dummy_clients (argv)
	console.log 'Starting dummy clients...'
	<~! detox-core.ready
	number_of_clients	= argv.number_of_clients
	wait_for			= argv.number_of_clients
	instances			= []

	for let i from 0 til argv.number_of_clients
		instance	= detox-core.Core(
			argv.bootstrap-node
			argv.stun || []
			10
			10
		)
			.once('ready', !->
				console.log('Node ' + i + ' is ready, #' + (argv.number_of_clients - wait_for + 1) + '/' + argv.number_of_clients)

				--wait_for
				if !wait_for
					ready_callback()
			)
		instances.push(instance)

	!function ready_callback
		console.log 'All dummy clients are ready'

	process.on('SIGINT', !->
		console.log "\nGot a SIGINT, stop everything and exit"
		for instance in instances
			instance.destroy()
		process.exit(0)
	)
	process.on('SIGTERM', !->
		console.log "\nGot a SIGTERM, stop everything and exit"
		for instance in instances
			instance.destroy()
		process.exit(0)
	)

!function generate_seed
	<~! detox-crypto.ready
	seed		= detox-core.generate_seed()
	keypair		= detox-crypto.create_keypair(seed)
	console.log('Seed: ' + Buffer.from(seed).toString('hex'))
	console.log('Node ID: ' + Buffer.from(keypair.ed25519.public).toString('hex'))
