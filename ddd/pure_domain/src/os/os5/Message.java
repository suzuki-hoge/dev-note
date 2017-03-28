package os.os5;

public class Message {
    private final String line;

    public Message(OsName os, Version version) {
        this.line = "error on " + os + ", java: " + version;
    }

    public String getLine() {
        return line;
    }
}
