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
a Web browser: https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person/entities.

It should output:
```json
<object xmlns:xsd="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/ia/Entity" type="Collection[simple.Person]">
  <attribute name="entities">
    <collection>
      <object type="simple.Person">
        <attribute name="$CreationTime">
          <null/>
        </attribute>
        <attribute name="$IdAttrib">
          <string>name</string>
        </attribute>
        <attribute name="description">
          <string></string>
        </attribute>
        <attribute name="name">
          <string>john.doe</string>
        </attribute>

      </object>
    </collection>
  </attribute>

</object>
```

Then, the event [SayHello](src/main/resources/say_hello.json) can be send.
When received, the related Rule agent of the DSI solution will emit a new event `Message`.
You can send it to DSI through the inbound Kafka topic by running the script [send_hello_event.sh](send_hello_event.sh).

The script `start_consumer.sh` can be used to monitor the Kafka outbound topic.
When a message is posted, the script will display the following output:
```
Output event from DSI: {  "$class": "simple.Message",  "$Id": "B40C5B1327B760A23011E87D17E55269",  "$TimeAttrib": "timestamp",  "$Timestamp": {    "$class": "java.time.ZonedDateTime",    "$value": "2018-08-17T15:13:19.801Z[GMT]"  },  "description": "hello",  "person": {    "key": "john.doe",    "type": "simple.Person"  },  "timestamp": "2018-08-17T15:13:19Z[GMT]"}
```
