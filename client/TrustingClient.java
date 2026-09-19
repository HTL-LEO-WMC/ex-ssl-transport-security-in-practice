// The same request, but the trust store is wired up in code instead of on the command line.
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.KeyStore;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;

public class TrustingClient {

    public static void main(String[] args) throws Exception {
        KeyStore trustStore = KeyStore.getInstance("PKCS12");
        try (InputStream in = new FileInputStream("tls/truststore.p12")) {
            trustStore.load(in, "changeit".toCharArray());
        }

        TrustManagerFactory factory = TrustManagerFactory.getInstance("PKIX");
        factory.init(trustStore);

        SSLContext context = SSLContext.getInstance("TLS");
        context.init(null, factory.getTrustManagers(), null);

        HttpClient client = HttpClient.newBuilder().sslContext(context).build();
        HttpRequest request = HttpRequest
                .newBuilder(URI.create("https://localhost:8443/hello"))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println(response.statusCode() + " " + response.body());
    }
}
