# Detox bootstrap node
Bootstrap node implementation for Detox network.

Recommended way to run a bootstrap node at the moment is using manually built Docker image:
```bash
git clone git@github.com:Detox/bootstrap-node.git detox-bootstrap-node
cd detox-bootstrap-node
docker build -f Dockerfile -t detox-bootstrap-node .
```

Now you can use obtained image as binary to start a bootstrap node:
```bash
docker run --rm -it -p 127.0.0.1:16882:16882 detox-bootstrap-node 0000000000000000000000000000000000000000000000000000000000000000 0.0.0.0 127.0.0.1
```
Execute is without arguments to get help message:
```bash
docker run --rm -it detox-bootstrap-node
```


## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
