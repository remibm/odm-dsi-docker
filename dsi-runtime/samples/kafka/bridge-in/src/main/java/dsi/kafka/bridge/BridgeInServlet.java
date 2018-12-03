package dsi.kafka.bridge;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * This class implements the input bridge which is forwarding Kafka messages to
 * DSI as a servlet.
 */
@WebServlet("/BridgeInServlet")
public class BridgeInServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	private static final Logger LOG = Logger.getLogger(BridgeInServlet.class.getName());

	private String kafkaHostname;
	private long KafkaPort;
	private String kafkaTopicIn;
	private String dsiInputConnectivityUrl;
	private String dsiUser;
	private String dsiPassword;

	private MessagesPoller messagesPooler;

	/**
	 * Init method of the servlet. This method starts the input messages pooler and
	 * initializes the output Kafka producer.
	 */
	@Override
	public void init(ServletConfig config) {
		try {

			kafkaHostname = System.getenv("KafkaHostname");
			KafkaPort = Long.parseLong(System.getenv("KafkaPort"));
			kafkaTopicIn = System.getenv("KafkaTopicIn").trim();
			dsiInputConnectivityUrl = System.getenv("InputConnectivityUrl");
			dsiUser = System.getenv("dsiUser");
			dsiPassword = System.getenv("dsiPassword");

			messagesPooler = new MessagesPoller(kafkaHostname, KafkaPort, kafkaTopicIn, dsiInputConnectivityUrl, dsiUser, dsiPassword);

			messagesPooler.start();

			LOG.info("BridgeInServlet started, connected to Kafka as consumer with hostname: "
					 + kafkaHostname
					 + ", Kafka port: "
					 + KafkaPort
					 + ", on Kafka topic: "
					 + kafkaTopicIn);
			LOG.info("BridgeInServlet forwarding events to DSI input connectivity with URL: "
					 + dsiInputConnectivityUrl);

		} catch (NumberFormatException e) {
			e.printStackTrace();

		}
	}

	/**
	 * This method releases all the resources.
	 */
	@Override
	public void destroy() {
		try {
			messagesPooler.setMessagePoolerStopped();
			messagesPooler.join();
			messagesPooler = null;
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Does nothing excepting returning a message.
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.getWriter().append("Served at: ").append(request.getContextPath());
		response.getWriter().append("Kafka events pooling Thread started: ").append("" + messagesPooler.isAlive());
	}

	/**
	 * doPost method of the Servlet. Does nothing excepting returning a message.
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.getWriter().append("Served at: ").append(request.getContextPath());
		response.getWriter().append("Kafka events pooling Thread started: ").append("" + messagesPooler.isAlive());
	}
}
