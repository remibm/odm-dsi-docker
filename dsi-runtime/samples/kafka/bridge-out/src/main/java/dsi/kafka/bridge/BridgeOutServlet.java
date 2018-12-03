package dsi.kafka.bridge;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.Properties;
import java.util.UUID;
import java.util.logging.Logger;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

/**
 * A servlet which receives the event from DSI outbound and forward them to a Kafka topic.
 *
 * <p>When DSI emits output events from connectivty, the messages are posted to the
 * current servlet. Then, the servlet forwards the output events to Kafka.<?p>
 */
@WebServlet("/BridgeOutServlet")
public class BridgeOutServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	private static final Logger LOG = Logger.getLogger(BridgeOutServlet.class.getName());

	private String kafkaHostname;
	private long kafkaPort;
	private String kafkaTopicOut;

	private Producer<String, String> producer;

	/**
	 * Init method of the servlet. This method starts the input messages poller and
	 * initializes the output Kafka producer.
	 */
	@Override
	public void init(ServletConfig config) {

		try {

			kafkaHostname = System.getenv("KafkaHostname");
			kafkaPort = Long.parseLong(System.getenv("KafkaPort"));
			kafkaTopicOut = System.getenv("KafkaTopicOut").trim();
			producer = createKafkaProducer();

			LOG.info("BridgeOutServlet started, connected to Kafka as producer with hostname: "
			         + kafkaHostname
					 + ", Kafka port: "
			         + kafkaPort
			         + ", on Kafka topic: "
			         + kafkaTopicOut);

		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
	}

	/**
	 *
	 * Destroy method of the servlet. This method releases all the resources.
	 *
	 */
	@Override
	public void destroy() {

		if (producer != null) {

			producer.close();
			producer = null;
		}
	}

	/**
	 * doGet method of the Servlet. Does nothing excepting returning a message.
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.getWriter().append("Served at: ").append(request.getContextPath());
	}

	/**
	 * doPost method of the Servlet. This method receives the output events from the
	 * DSI connectivity. It forwards the output events of DSI to Kafka.
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		try (BufferedReader rd = new BufferedReader(request.getReader())) {

			StringBuffer body = new StringBuffer();

			String line = null;

			while ((line = rd.readLine()) != null) {
				body.append(line);
			}

			LOG.info("DSI Event sent to topic: " + kafkaTopicOut + ", event value: " + body);

			if (producer != null) {

				producer.send(new ProducerRecord<String, String>(kafkaTopicOut, body.toString()));
			}

		} catch (Throwable t) {

			t.printStackTrace();

			throw new ServletException();
		}
	}

	/**
	 * Creates a Kafka Producer.
	 * 
	 * @return A Kafka Producer object.
	 */
	private Producer<String, String> createKafkaProducer() {

		Properties kafkaProps = new Properties();
		kafkaProps.put("bootstrap.servers", kafkaHostname + ":" + kafkaPort);
		kafkaProps.put("client.id", UUID.randomUUID().toString());
		kafkaProps.put("acks", "all");
		kafkaProps.put("retries", 0);
		kafkaProps.put("batch.size", 16384);
		kafkaProps.put("linger.ms", 1);
		kafkaProps.put("buffer.memory", 33554432);
		kafkaProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
		kafkaProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

		return new KafkaProducer<>(kafkaProps);
	}
}
