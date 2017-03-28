package os.os2;

public class Main {
    public static void main(String[] args) {
        Message message = new Message(
                System.getProperty("os.name"),
                System.getProperty("java.version")
        );

        message.echo(); // error on mac os x, java: 1.8.0_66
    }
}
