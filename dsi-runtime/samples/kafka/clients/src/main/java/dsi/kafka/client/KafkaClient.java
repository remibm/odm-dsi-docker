package dsi.kafka.client;

/**
 * CLI to publish messages to a Kafka top or display the messages sent to a
 * Kafka topic.
 */
public class KafkaClient {

	public static void main(String[] args) throws Exception {

		if ("publish".equals(args[0])) {

			KafkaMessagePublisher kafkaProducer = new KafkaMessagePublisher(args[1], args[2], args[3].trim());

			kafkaProducer.publishMessage(args[4]);

		} else if ("consume".equals(args[0])) {

			KafkaMessagesConsumer consumer = new KafkaMessagesConsumer(args[1], args[2], args[3].trim());

			consumer.consumeMessages();

		} else {

			throw new IllegalStateException("Invalid command, the command must be 'publish' or 'consume'.");
		}
	} 
}
