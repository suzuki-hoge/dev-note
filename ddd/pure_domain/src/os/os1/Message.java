package os.os1;

public class Message {
    private final String line;

    public Message() {
        this.line = "error on " + System.getProperty("os.name").toLowerCase() + ", java: " + System.getProperty("java.version");
    }

    public void echo() {
        System.out.println(line);
    }
}
