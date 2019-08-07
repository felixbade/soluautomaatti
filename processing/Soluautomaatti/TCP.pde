import java.net.*;
import java.io.*;
import java.security.*;

// Program
Socket socket;
PrintWriter tcpout;
BufferedReader tcpin;
boolean networkIsUp = false;
int lastMessageAt;

void setupTCP() {
  thread("tcpLoop");
  delay(200);
}

void tcpLoop() {
  while (true) {
    lastMessageAt = millis();
    thread("watchForTimeout");
    tcpSessionLoop();
    delay(500); // if the connection is lost, wait 500 ms before reconnecting
  }
}

void watchForTimeout() {
  while (networkIsUp) {
    int timeToTimeout = lastMessageAt + tcpTimeout - millis();
    if (timeToTimeout < 0) {
      logPrint("Timeout");
      closeConnection();
    } else {
      delay(timeToTimeout);
    }
  }
}

void tcpSessionLoop() {
  try { 
    socket = new Socket(host, port);
    tcpout = new PrintWriter(socket.getOutputStream(), true);
    tcpin = new BufferedReader(new InputStreamReader(socket.getInputStream()));
    
    // auth
    tcpout.println("nonce");
    String nonce = tcpin.readLine();
    String hash = sha256(nonce + password);
    tcpout.println("auth " + hash);
    String reply = tcpin.readLine();
    boolean authenticated = reply.equals("Success");
    if (authenticated) {
      println("Connected!");
      networkIsUp = true;
      arduinoAllowPublishing();
    } else {
      // we can't really do anything. just keep trying and hope for the best
      println("Authentication error");
      println(reply);
      return;
    }

    String inputLine;
    while ((inputLine = tcpin.readLine()) != null) {
      lastMessageAt = millis();
      inputLine = inputLine.replace("\n", "").replace("\r", "");
      handleTCPInput(inputLine);
    }
   
  } catch (UnknownHostException e) { 
    System.out.println("Sock: " + e.getMessage());
  } catch (EOFException e) {
    System.out.println("EOF: " + e.getMessage());
  } catch (IOException e) {
    System.out.println("IO: " + e.getMessage());
  } finally {
    closeConnection();
  }
}

void tcpSend(String text) {
  if (!networkIsUp) {
    return;
  }

  try {
    tcpout.println(text);
  } catch (NullPointerException e) {}
}

void closeConnection() {
  try {
    socket.close();
    networkIsUp = false;
  } catch (Exception e) {}
}

String sha256(String base) {
  try {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] hash = digest.digest(base.getBytes("UTF-8"));
    StringBuffer hexString = new StringBuffer();
    
    for (int i = 0; i < hash.length; i++) {
      String hex = Integer.toHexString(0xff & hash[i]);
      if (hex.length() == 1) hexString.append('0');
      hexString.append(hex);
    }
    
    return hexString.toString();
  } catch(Exception e) {
    throw new RuntimeException(e);
  }
}
