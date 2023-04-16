# Kafka Cluster Stack

This is a fully working template to launch a Kafka cluster with Docker Compose.

## Features

* Kafka UI
* Self-signed SASL/SSL with PLAIN mechanism

## Usage

In order to create a Kafka cluster, you need to do the following:
1. Generate SASL/SSL certificates
2. Generate JAAS config
3. Launch the cluster

### Generate SASL/TLS certificates

Script will generate self-signed certificates for Kafka cluster.
Kafka will use generated certificates for SASL/SSL. 
The certificates are generated using the `certs/generate.sh` script.

```bash
certs/build.sh
```

### Generate JAAS config

Script will generate JAAS config for Kafka cluster.

```bash
./jaas/build.sh
```

### Launch the cluster

Script will launch the cluster in the background.

```bash
./up.sh
```

### Stop the cluster

Script will stop the cluster.

```bash
./down.sh
```

### Remove certificates

Script will remove generated certificates.

```bash
certs/clean.sh
```
