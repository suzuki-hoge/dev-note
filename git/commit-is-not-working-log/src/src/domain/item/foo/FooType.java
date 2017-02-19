package domain.item.foo;

public enum FooType {
    A, B;

    public boolean isA() {
        return this == A;
    }
}
