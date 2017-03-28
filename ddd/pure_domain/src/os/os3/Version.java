package os.os3;

public class Version {
    private final String value = System.getProperty("java.version");

    @Override
    public String toString() {
        return value;
    }
}
