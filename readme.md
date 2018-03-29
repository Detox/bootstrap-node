# Detox bootstrap node
Bootstrap node implementation for Detox network.

## How to use
The easiest way is to start bootstrap node using Docker image, execute it without arguments to get help message with all supported commands and their arguments:
```bash
docker run --rm -it nazarpc/detox-bootstrap-node
```

### Start bootstrap node
If you want to create separate network - start without `-b` option, otherwise make sure to provide a few of existing nodes from the network you want to join.

```bash
docker run -d --name detox-bootstrap-node -p <ip>:16882:16882 nazarpc/detox-bootstrap-node <seed> 0.0.0.0 <domain>[ -b bootstrap_node]
```
* `ip` - publicly available IP
* `seed` - hex of 32-bytes seed from which DHT keypair is generated (make sure it is unique seed and keep it private)
* `domain` - publicly available domain name (or IP) that other nodes in the network will use in order to reach this node
* `bootstrap_node` - information about existing bootstrap node in the network (`-b` can be specified multiple times) in form `hex_node_id:domain_or_ip:port`

### Start dummy clients
While network is tiny, for communication we might need some dummy nodes that will facilitate proper network operation.

```bash
docker run -d --name detox-dummy-clients nazarpc/detox-bootstrap-node dummy-clients <number_of_clients> -b <bootstrap_node>
```
* `number_of_clients` - how many dummy clients need to be created
* `bootstrap_node` - information about existing bootstrap node in the network (`-b` can be specified multiple times) in form `hex_node_id:domain_or_ip:port`

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
