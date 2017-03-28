package os.os3;

public class Message {
    private final String line;

    public Message(OsName os, Version version) {
        this.line = "error on " + os + ", java: " + version;
    }

    public void echo() {
        System.out.println(line);
    }
}
