package os.os3;

public class Main {
    public static void main(String[] args) {
        Message message = new Message(
                new OsName(),
                new Version()
        );

        message.echo(); // error on mac os x, java: 1.8.0_66
    }
}
