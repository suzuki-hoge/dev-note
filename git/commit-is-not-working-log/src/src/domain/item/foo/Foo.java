package domain.item.foo;

public class Foo {
    private final FooId id;
    private final FooName name;
    private final FooType type;

    public Foo(FooId id, FooName name, FooType type) {
        this.id = id;
        this.name = name;
        this.type = type;
    }

    public boolean isTypeA() {
        return type.isA();
    }
}
