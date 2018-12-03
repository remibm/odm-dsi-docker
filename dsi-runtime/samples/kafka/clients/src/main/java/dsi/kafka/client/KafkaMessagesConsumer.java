package dsi.kafka.client;

import java.util.Arrays;
import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.TopicPartition;

/**
 * 
 *
 * Class that consumes message on a Kafka topic.
 *
 */
public class KafkaMessagesConsumer {

	/**
	 * Outpout Topic name listen by the bridge between DSI and Kafka.
	 */

	private static final long POLL_TIMEOUT = 10 * 1000;
	private static final long MESSAGES_CONSUMER_TIMEOUT = 5 * 60 * 1000;

	private final String kafkaHostname;
	private final String kafkaPort;
	private final String kafkaTopic;

	/**
	 * Class constructor.
	 * 
	 * @param kafkaHostname
	 *            Kafka hostname.
	 * @param kafkaPort
	 *            Kafka port.
	 * @param kafkaTopic
	 *            Kafka topic name.
	 */
	public KafkaMessagesConsumer(String kafkaHostname, String kafkaPort, String kafkaTopic) {

		this.kafkaHostname = kafkaHostname;
		this.kafkaPort = kafkaPort;
		this.kafkaTopic = kafkaTopic;
	}

	/**
	 * Method that consumes a message on a Kafka topic.
	 */
	public void consumeMessages() {

		try (Consumer<String, String> consumer = createKafkaConsumer()) {

			long startTime = System.currentTimeMillis();

			while ((System.currentTimeMillis() - startTime) < MESSAGES_CONSUMER_TIMEOUT) {

				System.out.println("Kafka events consumer: Waiting for event ...");

				ConsumerRecords<String, String> records = consumer.poll(POLL_TIMEOUT);

				for (TopicPartition partition : records.partitions()) {

					for (ConsumerRecord<String, String> record : records.records(partition)) {

						System.out.println("Output event from DSI: " + record.value());
					}
				}
			}

		} catch (Throwable e) {

			e.printStackTrace();
		}

		System.out.println("Kafka events consumer: exiting from program ...");
	}

	/**
	 * Method that creates a Kafka consumer.
	 * 
	 * @return A Kafka Consumer object.
	 */
	private Consumer<String, String> createKafkaConsumer() {

		Properties props = new Properties();
		props.put("bootstrap.servers", kafkaHostname + ":" + kafkaPort);
		props.put("client.id", UUID.randomUUID().toString());
		props.put("group.id", "test");
		props.put("enable.auto.commit", "true");
		props.put("auto.commit.interval.ms", "1000");
		props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

		System.out.println("Kafka configuration: " + props);

		Consumer<String, String> consumer = new KafkaConsumer<String, String>(props);
		consumer.subscribe(Arrays.asList(kafkaTopic));

		return consumer;
	}
}
