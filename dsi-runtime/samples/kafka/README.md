# Communication between ODM DSI and Apache Kafka

Apache Kafka is a distributed streaming platform which is widely used nowadays
in the enterprises for handling the communication and processing of multiple
services and applications.

This sample demonstrates a simple way to handle the communication between
Apache Kafka and DSI Runtime and uses Docker to simplify the deployment.

## Prerequisites

The following softwares are required for running this sample:
- JDK 8
- Apache Maven 3.5.3
- Docker 18.03.1
- docker-compose 1.17
- Docker image of the DSI runtime

To build the Docker image of DSI runtime, please refer to the appropriate [README.md](../../../README.md) file.

## Creates the Docker containers

This sample is using a [docker-compose script](./docker-compose.yml) which
is creating the Docker containers for the DSI runtime, Kafka and Zookeeper so it
can work without installing anything else.

To create the Docker containers for running DSI and Kafka by using a terminal:

Checkout the source of the sample:
```
git clone https://github.com/ODMDev/odm-dsi-docker
```

Go to sample directory:
```
cd dsi-runtime/samples/kafka/
```

Execute the `start.sh` scripts:
```
./start.sh
```

The script should end with:

```
CWMBE1146I: Reading the input file: /dropins/simple_solution-0.0.esa
CWMBE1475I: The connectivity server configuration file for the solution "simple_solution" contains the configuration required for the specified endpoints.
CWMBE1148I: Writing to the output file: /tmp/simple_solution-inbound.ear8314683510662034043.tmp
CWMBE1452I: Successfully deployed connectivity for the solution "simple_solution".
CWMBE1498I: Number of active inbound endpoints: 1
CWMBE1499I: Number of active outbound endpoints: 1
```

At this stage everything is running, DSI, and the Kafka/Zookeeper servers, and a
simple DSI solution is deployed for testing the communication between Kafka and
DSI.

## Test the sample

The event [CreatePerson](src/main/resources/create_person.json) is creating an entity.
You can send it to DSI through the inbound Kafka topic by running the script [create_person_entity.sh](create_person_entity.sh).

The DSI webapi can used to verify that the entity has been created, open the following URL with
a Web browser: https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person/entities
It should output:

1. On a second terminal, execute the kafka_consume.sh script to to receive later the output event,

	./start_consumer.sh

2. Again, on the first terminal, execute the 'say_hello.sh' script.

	./send_hello_event.sh

The event will be sent to the 'Person' entity and an output event will be emitted.

On the second terminal, you must see this output event printed.
