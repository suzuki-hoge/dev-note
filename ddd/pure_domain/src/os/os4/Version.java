package os.os4;

public class Version {
    private final String value;

    public Version(String value) {
        this.value = value;
    }

    @Override
    public String toString() {
        return value;
    }
}