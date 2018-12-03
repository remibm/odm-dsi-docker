package dsi.kafka.client;

import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

/**
 * Class that publishes a message to a Kafka topic.
 */
public class KafkaMessagePublisher {
	/**
	 * Input Topic name listens by the bridge between Kafka and DSI.
	 */
	private final String kafkaHostname;
	private final String kafkaPort;
	private final String kafkaTopic;

	/**
	 * Class constructor.
	 * 
	 * @param kafkaHostname
	 *            The Kafka hostname.
	 * @param kafkaPort
	 *            The kafka port.
	 * @param kafkaTopic
	 *            The Kafka topic name.
	 */
	public KafkaMessagePublisher(String kafkaHostname, String kafkaPort, String kafkaTopic) {

		this.kafkaHostname = kafkaHostname;
		this.kafkaPort = kafkaPort;
		this.kafkaTopic = kafkaTopic;
	}

	/**
	 * Method to publish a message on a Kafka topic.
	 * 
	 * @param message
	 *            A message string.
	 */
	public void publishMessage(String message) {

		try (Producer<String, String> producer = createKafkaProducer()) {

			System.out.println("Publishing event/message to DSI by Kafka on topic: " + kafkaTopic);

			ProducerRecord<String, String> record = new ProducerRecord<>(kafkaTopic, message);

			producer.send(record).get();

			System.out.println("Event/message published to Kafka on topic: " + kafkaTopic);

		} catch (Throwable t) {

			t.printStackTrace();
		}
	}

	/**
	 * Method that creates a Kafka producer.
	 * 
	 * @return A Kafka Producer object.
	 */
	private Producer<String, String> createKafkaProducer() {

		Properties kafkaProps = new Properties();
		kafkaProps.put("bootstrap.servers", kafkaHostname + ":" + kafkaPort);
		kafkaProps.put("acks", "all");
		kafkaProps.put("retries", 0);
		kafkaProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		kafkaProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		kafkaProps.put("client.id", UUID.randomUUID().toString());

		System.out.println("Producer configuration: " + kafkaProps);

		return new KafkaProducer<String, String>(kafkaProps);
	}
}