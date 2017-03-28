package os.os2;

public class Message {
    private final String line;

    public Message(String os, String version) {
        this.line = "error on " + os + ", java: " + version;
    }

    public void echo() {
        System.out.println(line);
    }
}
