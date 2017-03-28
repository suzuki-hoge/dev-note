package os.os3;

public class OsName {
    private final String value = System.getProperty("os.name");

    @Override
    public String toString() {
        return value;
    }
}
