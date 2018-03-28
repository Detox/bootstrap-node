``#!/usr/bin/env node``
/**
 * @package Detox bootstrap node
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
detox-bootstrap-node	= require('..')
detox-crypto			= require('@detox/crypto')
yargs					= require('yargs')

const SEED_LENGTH	= 32

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
		describe	: 'Port on which to listen'
	})
	.help()
	.argv

detox-bootstrap-node.Bootstrap_node(
	argv.seed
	[]
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
		console.log "Bootstrap node is ready, connect using:"
		console.log JSON.stringify({node_id, host, port}, null, '  ')
	)
