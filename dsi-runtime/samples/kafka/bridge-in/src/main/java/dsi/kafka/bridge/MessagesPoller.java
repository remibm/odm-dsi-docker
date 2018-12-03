package dsi.kafka.bridge;

import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.HttpURLConnection;
import java.net.Authenticator;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.security.KeyException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.logging.Logger;
import java.util.UUID;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.TopicPartition;

/**
 * A Thread which polls messages from a Kafka topic, extracts the events and
 * forward the events to DSI.
 */
public class MessagesPoller extends Thread {

	private static final Logger LOG = Logger.getLogger(MessagesPoller.class.getName());

	private final String kafkaHostname;
	private final long kafkaPort;
	private final String topic;
	private final String dsiUrl;
	private final String dsiUser;
	private final String dsiPassword;

	private volatile boolean isRunning = true;

	/**
	 * Class constructor.
	 *
	 * @param consumerId
	 *            The consumer Id.
	 * @param kafkaHostname
	 *            The Kafka hostname.
	 * @param kafkaPort
	 *            The Kafka port.
	 * @param topic
	 *            The input kafka topic name.
	 * @param dsiUrl
	 *            The url of DSI input connectivity.
	 */
	public MessagesPoller(String kafkaHostname, long kafkaPort, String topic, String dsiUrl, String dsiUser, String dsiPassword) {
		this.kafkaHostname = kafkaHostname;
		this.kafkaPort = kafkaPort;
		this.topic = topic;
		this.dsiUrl = dsiUrl;
		this.dsiUser = dsiUser;
		this.dsiPassword = dsiPassword;
	}

	/**
	 * Polls messages from the Kafka input topic.
	 *
	 * <p>It extracts the events from an input
	 * Kafka topic. Each set of events is forwarded to DSI and removed from Kafka after
	 * committing the transaction. </p>
	 */
	public void run() {
		try {
			disableCertif();
		} catch (NoSuchAlgorithmException | KeyException e1) {
			e1.printStackTrace();
		}

		try (Consumer<String, String> consumer = createConsumer()) {

			while (isRunning) {
				LOG.info("Polling ...");

				ConsumerRecords<String, String> records = consumer.poll(Long.MAX_VALUE);
				for (TopicPartition partition : records.partitions()) {

					long lastOffset = -1;
					String event = null;

					List<ConsumerRecord<String, String>> partitionRecords = records.records(partition);
					for (ConsumerRecord<String, String> record : partitionRecords) {

						lastOffset = record.offset();
						event = record.value();

						LOG.info("Received message: offset = " + lastOffset + ", event = " + event);

						int responseCode = sendToDSI(dsiUrl, event, dsiUser, dsiPassword);
						if (responseCode != 200) {
							LOG.info("Post to DSI response code: " + responseCode);
							LOG.info("Event not distributed to DSI : " + record.value());
							break;

						} else {
							LOG.info("Post event to DSI: " + record.value());
						}
					}

					if (lastOffset != -1) {

						Map<TopicPartition, OffsetAndMetadata> map = new HashMap<TopicPartition, OffsetAndMetadata>();
						map.put(partition, new OffsetAndMetadata(lastOffset + 1));

						consumer.commitSync(map);
					}
				}
			}

		} catch (Throwable e) {

			e.printStackTrace();
		}
	}

	/**
	 * This method is called to notify the end of the Thread.
	 */
	void setMessagePoolerStopped() {

		isRunning = false;
	}

	/**
	 * Methods that creates a Kafka consumer.
	 *
	 * @return A Kafka Consumer object.
	 */
	private Consumer<String, String> createConsumer() {

		Properties props;

		props = new Properties();
		props.put("bootstrap.servers", kafkaHostname + ":" + kafkaPort);
		props.put("group.id", "kafkaIn");
		props.put("client.id", UUID.randomUUID().toString());
		props.put("enable.auto.commit", "false");
		props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

		LOG.info("Kafka configuration: " + props);

		Consumer<String, String> consumer = new KafkaConsumer<>(props);
		consumer.subscribe(Arrays.asList(topic));

		LOG.info("MessagesPooler subscribed to " + topic);

		return consumer;
	}

	/**
	 * Disables SSL.
	 *
	 * @throws NoSuchAlgorithmException
	 * @throws KeyException
	 */
	private static void disableCertif() throws NoSuchAlgorithmException, KeyException {
		TrustManager[] mgrs;
		SSLContext sc;

		mgrs = new TrustManager[] { new X509TrustManager() {
			public java.security.cert.X509Certificate[] getAcceptedIssuers() {
				return null;
			}

			public void checkClientTrusted(X509Certificate[] certs, String authType) {
			}

			public void checkServerTrusted(X509Certificate[] certs, String authType) {
			}
		} };

		sc = SSLContext.getInstance("SSL");
		sc.init(null, mgrs, new java.security.SecureRandom());
		SSLContext.setDefault(sc);
	}

	/**
	 *
	 * @param url
	 *            DSI connectivity input url.
	 * @param event
	 *            The event to forward to DSI.
	 * @return A result code : 200 if the event has been effectively transmitted to
	 *         DSI, an error code otherwise.
	 */
	private static int sendToDSI(String url, String event, String user, String password) {

		HttpURLConnection connection = null;
		Authenticator.setDefault (new Authenticator() {
		    protected PasswordAuthentication getPasswordAuthentication() {
		        return new PasswordAuthentication (user, password.toCharArray());
		    }
		});
		try {
			URL obj = new URL(url);
			connection = (HttpURLConnection) obj.openConnection();

			connection.setRequestMethod("POST");
			connection.setDoOutput(true);
			connection.setUseCaches(false);
			connection.setAllowUserInteraction(false);
			connection.setRequestProperty("Content-Type", "application/json");

			OutputStream out = connection.getOutputStream();
			Writer writer = new OutputStreamWriter(out, "UTF-8");
			writer.write(event);
			writer.close();
			out.close();

			return connection.getResponseCode();

		} catch (Throwable t) {
			t.printStackTrace();

			return -1;

		} finally {

			connection.disconnect();
		}
	}
}
