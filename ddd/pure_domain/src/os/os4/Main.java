package os.os4;

public class Main {
    public static void main(String[] args) {
        Message message = new Message(
                new OsName(System.getProperty("os.name")),
                new Version(System.getProperty("java.version"))
        );

        message.echo(); // error on mac os x, java: 1.8.0_66
    }
}
