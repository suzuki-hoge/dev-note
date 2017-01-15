package doc_path;

public @interface DocPath {
    Path path();

    String note() default "";
}
